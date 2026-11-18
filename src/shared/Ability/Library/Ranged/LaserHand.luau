--!strict
-- Services
-- Packages
-- Modules
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new("ranged_laser-hand", {
	ReleaseDelay = 0.6,
	Duration = 2,
	Limb = "RightHand",
	Speed = 120,
	Lifetime = 10,
	Size = Vector3.new(0.4, 0.4, 4),
	Color = BrickColor.new("Cyan").Color,
	LaunchSound = "PewPew",
})
