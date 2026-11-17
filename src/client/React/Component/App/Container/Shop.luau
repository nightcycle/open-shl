--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ShopMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local ERROR_DURATION = 4
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
	local isBusyRef = React.useRef(false)

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
					if isBusyRef.current then
						return
					end
					isBusyRef.current = true
					-- no robux products yet, the server hands the product out for free
					task.spawn(function()
						local purchaseRes = NetworkService:Invoke(RemoteDefinition.PurchaseProduct, action.ProductId)
						isBusyRef.current = false
						if not isMountedRef.current then
							return
						end
						if purchaseRes.IsErr then
							setErrorMessage(purchaseRes.Value)
						else
							setErrorMessage(nil)
						end
					end)
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("Shop")
				end
			end,
		} :: ShopMenu.Properties
	)
end
