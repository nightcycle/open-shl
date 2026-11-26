--!strict
-- Services
-- Packages
-- Modules
local FreezeRay = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FreezeRay")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(FreezeRay, {
	CastAnimation = "GunShooting",
	HoldAnimation = "GunHolding",
}):Build()
