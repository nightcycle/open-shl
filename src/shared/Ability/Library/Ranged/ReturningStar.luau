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
-- a star that floats out a little way + comes back to the hand: it hurts the first it meets, out or back. the one
-- that's thrown far + sticks is another power
return ShotFactory.new("ranged_returning-star", {
	ReleaseDelay = 0.05,
	Duration = 2,
	Limb = "RightHand",
	Speed = 45,
	-- it turned around where a look every quarter of a second found it 20 studs out: at 22.5
	Lifetime = 0.5,
	IsReturning = true,
	Size = Vector3.new(0.25, 0.05, 0.25),
	Color = Color3.fromRGB(163, 162, 165),
	Material = Enum.Material.SmoothPlastic,
	Mesh = "ThrowingStar",
	MeshScale = Vector3.new(3, 3, 3),
	-- on its edge, the way it leaves the hand
	Turn = CFrame.Angles(0, 0, math.rad(90)),
})
