--!strict
-- Services
-- Packages
-- Modules
local HitscanBow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/HitscanBow")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- it's held + shot the way a gun is
return RayFactory.new(HitscanBow, {
	CastAnimation = "GunShooting",
	HoldAnimation = "GunHolding",
}):Build()
