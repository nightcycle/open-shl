--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EmoteService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Emote")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ActionsMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ActionsMenu")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
type ExpressionId = ActionsMenu.ExpressionId
type EmoteId = ActionsMenu.EmoteId
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(EmoteService.IsInitialized, `the emote service isn't initialized`)
	local expressionId: ExpressionId? = useCharacterAttribute(AttributeDefinition.ExpressionId)
	local isMasked = useCharacterAttribute(AttributeDefinition.IsMasked)
	local isHandcuffed = useCharacterAttribute(AttributeDefinition.IsHandcuffed)
	local isApartmentLocked = usePlayerAttribute(AttributeDefinition.IsApartmentLocked)
	local emoteId: EmoteId? = useSignalState(EmoteService.EmoteChanged, function(): EmoteId?
		return EmoteService:GetEmoteId()
	end) :: EmoteId?

	return e(
		ActionsMenu,
		{
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.3, 0.5),
			Size = UDim2.fromScale(0.4, 0.5),
			ExpressionId = expressionId,
			EmoteId = emoteId,
			IsMasked = isMasked,
			IsHandcuffed = isHandcuffed,
			IsApartmentLocked = isApartmentLocked,
			OnAction = function(action: ActionsMenu.ActionInfo)
				if action.Type == "SetExpression" then
					NetworkService:Fire(RemoteDefinition.SetExpression, action.ExpressionId)
				elseif action.Type == "SetEmote" then
					if not action.EmoteId then
						EmoteService:Stop()
						return
					end
					local emoteRes = EmoteService:Play(action.EmoteId)
					if emoteRes.IsErr then
						warn(`emote err: {emoteRes.Value}`)
						return
					end
					-- the cuffs + an emote don't go together, the cuffs come off for it
					if isHandcuffed then
						NetworkService:Fire(RemoteDefinition.SetHandcuffed, false)
					end
				elseif action.Type == "SetMasked" then
					NetworkService:Fire(RemoteDefinition.SetMasked, action.IsMasked)
				elseif action.Type == "SetHandcuffed" then
					NetworkService:Fire(RemoteDefinition.SetHandcuffed, action.IsHandcuffed)
				elseif action.Type == "SetApartmentLocked" then
					NetworkService:Fire(RemoteDefinition.SetApartmentLocked, action.IsApartmentLocked)
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("Actions")
				end
			end,
		} :: ActionsMenu.Properties
	)
end
