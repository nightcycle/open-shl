--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local BuildService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Build")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ResidenceService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Residence")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local BuildMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BuildMenu")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
type ClientFunction<V, T> = RemoteDefinition.ClientFunction<V, T>
type ResidenceState = ResidenceService.ResidenceState
type Refusal = BuildMenu.Refusal
export type Properties = {}
-- Constants
local REFUSAL_DURATION = 4
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(BuildService.IsInitialized, `the build service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ResidenceService.IsInitialized, `the residence service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local selectedFurnitureId: string? = useSignalState(BuildService.FurnitureIdChanged, function(): string?
		return BuildService:GetFurnitureId()
	end)
	-- the menu is only up inside of the player's own residence
	local state: ResidenceState? = useSignalState(ResidenceService.StateChanged, function(): ResidenceState?
		return ResidenceService:GetState()
	end)
	local pendingId: string?, setPendingId: (string?) -> () = React.useState(nil :: string?)
	local refusal: Refusal?, setRefusal: (Refusal?) -> () = useTimedState(REFUSAL_DURATION)
	local isMountedRef = useIsMounted()
	local isPurchasingRef = React.useRef(false)
	local isApplyingRef = React.useRef(false)
	React.useEffect(function()
		local connection = BuildService.RequestFailed:Connect(function(message: string)
			setRefusal({
				Message = message,
			})
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	local function purchase(remote: ClientFunction<true, string>, id: string)
		-- one purchase at a time, a card that's hammered doesn't pile them up
		if isPurchasingRef.current then
			return
		end
		isPurchasingRef.current = true
		setPendingId(id)
		task.spawn(function()
			local purchaseRes = NetworkService:Invoke(remote, id)
			isPurchasingRef.current = false
			if not isMountedRef.current then
				return
			end
			setPendingId(nil)
			if purchaseRes.IsErr then
				setRefusal({
					Message = purchaseRes.Value,
					Id = id,
				})
			else
				setRefusal(nil)
			end
		end)
	end

	return e(
		BuildMenu,
		{
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.55),
			Size = UDim2.fromScale(0.3, 0.8),
			SelectedFurnitureId = selectedFurnitureId,
			AppliedThemeId = if state then state.Layout.ThemeId else nil,
			PendingId = pendingId,
			Refusal = refusal,
			OnAction = function(action: BuildMenu.ActionInfo)
				if action.Type == "PurchaseFurniture" then
					purchase(RemoteDefinition.PurchaseFurniture, action.FurnitureId)
				elseif action.Type == "PurchaseTheme" then
					purchase(RemoteDefinition.PurchaseTheme, action.ThemeId)
				elseif action.Type == "SelectFurniture" then
					local furnitureRes = BuildService:SetFurnitureId(action.FurnitureId)
					if furnitureRes.IsErr then
						setRefusal({
							Message = furnitureRes.Value,
						})
					else
						setRefusal(nil)
					end
				elseif action.Type == "ApplyTheme" then
					if isApplyingRef.current then
						return
					end
					isApplyingRef.current = true
					task.spawn(function()
						local themeRes = BuildService:ApplyTheme(action.ThemeId)
						isApplyingRef.current = false
						if not isMountedRef.current then
							return
						end
						if themeRes.IsErr then
							setRefusal({
								Message = themeRes.Value,
								Id = action.ThemeId,
							})
						else
							setRefusal(nil)
						end
					end)
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("Build")
				end
			end,
		} :: BuildMenu.Properties
	)
end
