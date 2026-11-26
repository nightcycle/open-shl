--!strict
-- Services
-- Packages
-- Modules
local LaserVision = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserVision")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- eyes hold nothing out: the avatar stands the way it stood + nods with every pair of rays
return RayFactory.new(LaserVision, {
	CastAnimation = "HeadShot",
}):Build()
