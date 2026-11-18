--!strict
-- Services
-- Packages
-- Modules
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type CombatRule = CombatType.CombatRule
-- Constants
-- a hit takes off what its power says + that's all there is to it
local RULE: CombatRule = {
	PlayerScale = 1,
	IsMenuSafe = false,
}
-- Variables
-- References
-- Private Functions
-- Class
return RULE
