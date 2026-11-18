--!strict
-- Services
-- Packages
-- Modules
local IceHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/IceHand")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(IceHand, {
	CastAnimation = "PowerShot",
}):Build()
