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
return ShotFactory.new("ranged_throwing-star", {
	ReleaseDelay = 0.6,
	Duration = 2,
	Limb = "RightHand",
	Speed = 150,
	Lifetime = 10,
	-- it's thrown rather than shot: it falls like anything else that's let go of
	Gravity = 196.2,
	Size = Vector3.new(0.25, 0.05, 0.25),
	Color = BrickColor.new("Medium stone grey").Color,
	Material = Enum.Material.SmoothPlastic,
	Mesh = "ThrowingStar",
	MeshScale = Vector3.new(3, 3, 3),
	-- on its edge, the way it leaves the hand
	Turn = CFrame.Angles(0, 0, math.rad(90)),
	IsSticking = true,
})
