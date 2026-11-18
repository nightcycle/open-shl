--!strict
-- Services
-- Packages
-- Modules
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type CombatRule = CombatType.CombatRule
-- Constants
-- a power lists what it takes off anything, a hit on somebody's character is half as much again + sends them off.
-- health comes back the way the engine hands it out by itself: a hundredth of it a second
local RULE: CombatRule = {
	PlayerScale = 1.5,
	IsMenuSafe = true,
	Knockback = {
		Speed = 80,
		Duration = 0.2,
		MaxForce = Vector3.new(20000, 0, 20000),
		Power = 1250,
	},
	Regeneration = {
		Amount = 1,
		Interval = 1,
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return RULE
