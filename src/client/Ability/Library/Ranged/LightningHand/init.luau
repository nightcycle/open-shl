--!strict
-- Services
-- Packages
-- Modules
local LightningHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LightningHand")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LightningHand, {
	CastAnimation = "PowerShot",
}):Build()
