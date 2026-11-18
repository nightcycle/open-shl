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
return ShotFactory.new("ranged_laser-eyes", {
	ReleaseDelay = 0.2,
	Duration = 0.5,
	Limb = "Head",
	-- the eyes sit a little above the middle of the head
	Offset = Vector3.new(0, 0.2, 0),
	Speed = 120,
	Lifetime = 10,
	Size = Vector3.new(0.4, 0.4, 4),
	Color = BrickColor.new("Cyan").Color,
	LaunchSound = "PewPew",
})
