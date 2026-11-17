--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local DatabaseMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/DatabaseMenu")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
type PublicProfile = SessionService.PublicProfile
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local profiles = useSignalState(SessionService.ProfilesChanged, function(): { PublicProfile }
		return SessionService:GetProfiles()
	end)

	return e(
		DatabaseMenu,
		{
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.25, 0.5),
			Size = UDim2.fromScale(0.5, 0.6),
			Profiles = profiles,
			OnAction = function(action: DatabaseMenu.ActionInfo)
				if action.Type == "Exit" then
					ShellService:ClosePanel("Database")
				end
			end,
		} :: DatabaseMenu.Properties
	)
end
