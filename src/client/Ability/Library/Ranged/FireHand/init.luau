--!strict
-- Services
-- Packages
-- Modules
local FireHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FireHand")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(FireHand, {
	CastAnimation = "PowerShot",
}):Build()
