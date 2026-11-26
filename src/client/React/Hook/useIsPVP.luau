--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- if players fight on this server, as of now: the owner of a private server may change that while it's being played.
-- a place that has it baked in is told once + never again
return function(): boolean
	local isPVP, setIsPVP = React.useState(ModeDefinition.getIfPVPEnabled)
	React.useEffect(function()
		-- it tells at once, so a change between the render + the effect isn't missed
		return ModeDefinition.observe(setIsPVP)
	end, {})
	return isPVP
end
