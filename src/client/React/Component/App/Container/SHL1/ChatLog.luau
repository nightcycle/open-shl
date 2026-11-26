--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ChatService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Chat")
-- Components
local ChatLog = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ChatLog")
-- Hooks
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getLines(): { string }
	assert(ChatService.IsInitialized, `the chat service isn't initialized`)
	return ChatService:GetLines()
end

local function getIfMuting(): boolean
	assert(ChatService.IsInitialized, `the chat service isn't initialized`)
	return ChatService:GetIfMuting()
end
-- Class
-- the log is read with the hud + gone with it, the way the old place hid it in its creator. what was said meanwhile
-- is in it when it's back: the lines are the service's to keep
return function(): React.ReactNode
	assert(ChatService.IsInitialized, `the chat service isn't initialized`)
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)
	local lines = useSignalState(ChatService.Changed, getLines)
	local isMuting = useSignalState(ChatService.Changed, getIfMuting)
	-- the mode the lines of others are held against is the one the player of this client tells of themselves
	local isPeaceful = usePlayerAttribute(AttributeDefinition.IsPlayerPeaceful) == true
	if not isGameplayHudVisible then
		return nil
	end
	return e(
		ChatLog,
		{
			Size = UDim2.fromScale(1, 1),
			Lines = lines,
			IsPeaceful = isPeaceful,
			IsMuting = isMuting,
			OnAction = function(action: ChatLog.ActionInfo)
				if action.Type == "ToggleMute" then
					ChatService:SetMuting(not isMuting)
				end
			end,
		} :: ChatLog.Properties
	)
end
