--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local Rules = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Rules")
-- Hooks
-- Contexts
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the rules are read where another game flies its player in: after the load, on every join. agreeing to them is the
-- only way on
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	return e(
		Rules,
		{
			Size = UDim2.fromScale(1, 1),
			OnAction = function(action: Rules.ActionInfo)
				if action.Type == "Agree" then
					ShellService:FinishBootPhase("Intro")
				end
			end,
		} :: Rules.Properties
	)
end
