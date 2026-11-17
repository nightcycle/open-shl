--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
local QuestBanner = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/QuestBanner")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
type QuestState = SessionService.QuestState
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local quest = useSignalState(SessionService.QuestChanged, function(): QuestState?
		return SessionService:GetQuest()
	end)
	if not BUILD_CONFIG.QUESTS_ENABLED then
		return nil
	end

	return e(
		QuestBanner,
		{
			Size = UDim2.fromScale(1, 1),
			Quest = quest,
			OnAction = function(action: QuestBanner.ActionInfo)
				if action.Type == "Cancel" then
					NetworkService:Fire(RemoteDefinition.CancelQuest, nil)
				end
			end,
		} :: QuestBanner.Properties
	)
end
