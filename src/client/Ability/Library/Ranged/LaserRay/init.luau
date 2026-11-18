--!strict
-- Services
-- Packages
-- Modules
local LaserRay = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserRay")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(LaserRay, {
	CastAnimation = "GunShooting",
	HoldAnimation = "GunHolding",
}):Build()
