--!strict
-- Services
-- Packages
-- Modules
local MagicHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/MagicHand")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(MagicHand, {
	CastAnimation = "PowerShot",
}):Build()
