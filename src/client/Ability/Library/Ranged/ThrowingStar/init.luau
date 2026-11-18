--!strict
-- Services
-- Packages
-- Modules
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
local ThrowingStar = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/ThrowingStar")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(ThrowingStar, {
	CastAnimation = "PowerShot",
}):Build()
