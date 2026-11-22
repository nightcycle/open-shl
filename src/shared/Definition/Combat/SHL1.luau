--!strict
-- Services
-- Packages
-- Modules
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type CombatRule = CombatType.CombatRule
-- Constants
-- a hit takes off what its power says, from one who fights onto one who fights: whoever sat fights out hurts nobody +
-- nobody hurts them. whoever just came in is left alone for as long as the force field of their spot is up, health
-- comes back by itself 5 every 3 seconds. a menu shelters whoever sits in it, so nobody gets into one for a quarter
-- of a minute after they lost health or took it off somebody
local RULE: CombatRule = {
	PlayerScale = 1,
	IsMenuSafe = true,
	IsOptional = true,
	IsShieldSafe = true,
	Fighting = {
		Duration = 15,
		MaxDuration = 30,
	},
	Regeneration = {
		Amount = 5,
		Interval = 3,
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return RULE
