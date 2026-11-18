--!strict
-- Services
-- Packages
-- Modules
local LaserEyes = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserEyes")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LaserEyes, {
	CastAnimation = "HeadShot",
}):Build()
