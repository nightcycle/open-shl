--!strict
-- Services
-- Packages
-- Modules
local FireRay = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FireRay")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(FireRay, {
	CastAnimation = "GunShooting",
	HoldAnimation = "GunHolding",
}):Build()
