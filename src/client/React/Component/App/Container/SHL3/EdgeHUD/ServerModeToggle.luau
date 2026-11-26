--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Components
local ServerModeToggle = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerModeToggle")
-- Hooks
local useIsPVP = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsPVP")
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
-- Contexts
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- only the owner of a private server has the button: the server tells them they are, the old place had the client
-- look that up + took the flip from anybody. what's read on it is what the server says it plays by, so it's right
-- from the first frame + for an owner who comes back. a press asks for the other mode by name
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local isOwner = usePlayerAttribute(AttributeDefinition.IsServerOwner)
	local isPVP = useIsPVP()
	-- the server answers one ask at a time, a second one would only be turned down
	local isBusyRef = React.useRef(false)
	if not isOwner then
		return nil
	end

	return e(
		ServerModeToggle,
		{
			Size = UDim2.fromScale(1, 1),
			IsPVP = isPVP,
			OnAction = function(action: ServerModeToggle.ActionInfo)
				if action.Type ~= "Toggle" or isBusyRef.current then
					return
				end
				isBusyRef.current = true
				task.spawn(function()
					-- the owner is only ever turned down for pressing too fast, which the old place said nothing
					-- about either: the button goes on reading what the server plays by
					NetworkService:Invoke(RemoteDefinition.SetServerPVP, not isPVP)
					isBusyRef.current = false
				end)
			end,
		} :: ServerModeToggle.Properties
	)
end
