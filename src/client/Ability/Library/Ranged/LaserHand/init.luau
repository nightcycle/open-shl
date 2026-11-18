--!strict
-- Services
-- Packages
-- Modules
local LaserHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserHand")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LaserHand, {
	CastAnimation = "PowerShot",
}):Build()
