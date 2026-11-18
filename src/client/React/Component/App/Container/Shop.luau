--!strict
--!native
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ShopMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
type ProductDefinition = ProductDefinition.ProductDefinition
export type Properties = {}
-- Constants
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
		ShopMenu,
		{
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.35, 0.5),
			Size = UDim2.fromScale(0.3, 0.3),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ErrorMessage = errorMessage,
			OnAction = function(action: ShopMenu.ActionInfo)
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
		} :: ShopMenu.Properties
	)
end
