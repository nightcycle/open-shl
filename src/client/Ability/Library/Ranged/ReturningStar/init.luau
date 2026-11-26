--!strict
-- Services
-- Packages
-- Modules
local ReturningStar = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/ReturningStar")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(ReturningStar, {
	CastAnimation = "PowerShot",
}):Build()
