--!strict
-- Services
-- Packages
-- Modules
local Minigun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Minigun")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the shot is played with every ray that leaves, not with the click
return RayFactory.new(Minigun, {
	FireAnimation = "GunShooting",
	HoldAnimation = "GunHolding",
}):Build()
