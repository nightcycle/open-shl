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
return ShotFactory.new("ranged_magic-hand", {
	ReleaseDelay = 0.6,
	Duration = 2,
	Limb = "RightHand",
	Speed = 80,
	Lifetime = 10,
	Size = Vector3.new(0.4, 0.4, 4),
	Color = BrickColor.new("Lime green").Color,
	HasSparkles = true,
	-- stood on its end, so what it gives off comes from the whole height of it
	Turn = CFrame.Angles(math.pi / 2, 0, 0),
})
