--!strict
--!native
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
local ShopMenuTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu/Types")
type ProductDefinition = ProductDefinition.ProductDefinition
type Layout = ShopMenuTypes.Component
type Placement = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
	SizeConstraint: Enum.SizeConstraint,
}
export type Properties = {}
-- Constants
-- how the shop is laid out is the game's own, the layout of another game is never required
local Layout: Layout = GameDefinition.pick({
	shl1 = function(): Layout
		error(`shl1 has no shop yet`)
	end,
	shl2 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu")
	end,
	shl3 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/RobuxShop")
	end,
})
local PLACEMENT: Placement = {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0.35, 0.5),
	Size = UDim2.fromScale(0.3, 0.3),
	SizeConstraint = Enum.SizeConstraint.RelativeXX,
}
-- where the panel is + how large is the game's own as well
local GAME_PLACEMENT: Placement = GameDefinition.tune(PLACEMENT, {
	-- where its panel was: the middle of the screen, 0.45 of its width by 0.3 of it
	shl3 = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.45, 0.3),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
	},
})
local ERROR_DURATION = 4
-- a product is free in studio, the server hands it over. anywhere else it's paid for through the prompt of the engine
local IS_STUDIO = RunService:IsStudio()
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local errorMessage: string?, setErrorMessage: (string?) -> () = useTimedState(ERROR_DURATION)
	local isMountedRef = useIsMounted()
	-- the product a purchase is out for, until the server or the prompt said how it went
	local purchasingRef: { current: ProductDefinition? } = React.useRef(nil :: ProductDefinition?)

	-- a prompt doesn't answer whoever opened it, that it's over is only heard of here. what was paid for isn't the
	-- business of the client: the server is told by the engine + the balance or the pass shows up once it's granted
	React.useEffect(function()
		if IS_STUDIO then
			return function() end
		end
		local function finish(legacyId: number, isGamePass: boolean)
			local definition = purchasingRef.current
			if
				definition
				and definition.LegacyId == legacyId
				and ProductDefinition.getIfGamePass(definition) == isGamePass
			then
				purchasingRef.current = nil
			end
		end
		local productConnection = MarketplaceService.PromptProductPurchaseFinished:Connect(
			function(userId: number, productId: number)
				if userId == Players.LocalPlayer.UserId then
					finish(productId, false)
				end
			end
		)
		local passConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player: Player, passId: number)
				if player == Players.LocalPlayer then
					finish(passId, true)
				end
			end
		)
		return function()
			productConnection:Disconnect()
			passConnection:Disconnect()
		end
	end, {})

	return e(
		Layout,
		{
			AnchorPoint = GAME_PLACEMENT.AnchorPoint,
			Position = GAME_PLACEMENT.Position,
			Size = GAME_PLACEMENT.Size,
			SizeConstraint = GAME_PLACEMENT.SizeConstraint,
			ErrorMessage = errorMessage,
			OnAction = function(action: ShopMenuTypes.ActionInfo)
				if action.Type == "Purchase" then
					-- one purchase at a time, a card that's hammered doesn't pile them up
					if purchasingRef.current then
						return
					end
					local definitionRes = ProductDefinition.get(action.ProductId)
					if definitionRes.IsErr then
						setErrorMessage(definitionRes.Value)
						return
					end
					local definition = definitionRes.Value
					if IS_STUDIO then
						purchasingRef.current = definition
						task.spawn(function()
							local purchaseRes = NetworkService:Invoke(RemoteDefinition.PurchaseProduct, definition.Id)
							purchasingRef.current = nil
							if not isMountedRef.current then
								return
							end
							if purchaseRes.IsErr then
								setErrorMessage(purchaseRes.Value)
							else
								setErrorMessage(nil)
							end
						end)
						return
					end
					purchasingRef.current = definition
					-- a prompt that never opened never ends either
					local isPrompted = pcall(function()
						if ProductDefinition.getIfGamePass(definition) then
							MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, definition.LegacyId)
						else
							MarketplaceService:PromptProductPurchase(Players.LocalPlayer, definition.LegacyId)
						end
					end)
					if isPrompted then
						setErrorMessage(nil)
					else
						purchasingRef.current = nil
						setErrorMessage(`"{definition.Name}" can't be bought right now`)
					end
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("Shop")
				end
			end,
		} :: ShopMenuTypes.Properties
	)
end
