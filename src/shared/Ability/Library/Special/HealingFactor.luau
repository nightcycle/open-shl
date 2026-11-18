--!strict
-- Services
-- Packages
-- Modules
local ToggleFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Toggle")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out heals. it then stays on for a while with nothing left to give: the click that comes next
-- only turns it off
return ToggleFactory.new("special_healing-factor", {
	Duration = 15,
})
