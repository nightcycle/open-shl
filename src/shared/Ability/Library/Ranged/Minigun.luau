--!strict
-- Services
-- Packages
-- Modules
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
-- Constants
-- how the hand holds the gun
local GRIP = CFrame.new(0, -0.5, 0.95) * CFrame.Angles(math.rad(90), math.rad(180), 0)
-- Variables
-- References
-- Private Functions
-- Class
-- a click is four rays in a row, each at what the click pointed at from wherever the muzzle is by then
return RayFactory.new("ranged_minigun", {
	-- four rays a tenth of a second apart, then a fifth of a second + the second it's listed with
	Duration = 1.6,
	ReleaseDelay = 0.1,
	Burst = { Count = 4, Interval = 0.1 },
	Limb = "RightHand",
	-- the muzzle
	Offset = GRIP:Inverse() * Vector3.new(0, 0, -2),
	Range = 500,
	Beams = {
		-- amber whatever the suit
		{
			Thickness = 0.1,
			Transparency = 0.2,
			Lifetime = 0.07,
			Color = Color3.fromRGB(255, 176, 0),
			IsPlain = true,
		},
	},
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.5, 0.5, 4),
			Offset = GRIP,
			Color = Color3.fromRGB(50, 50, 50),
			Material = Enum.Material.SmoothPlastic,
			Mesh = "Minigun",
			MeshScale = Vector3.one * 0.18,
			MeshOffset = Vector3.new(-0.2, -0.17, 0.15),
			Delay = 0.3,
			Linger = 0.3,
		},
	},
	HasColoredProps = true,
	FireSound = "GunShot",
	Flare = { Particle = "Flash", Duration = 0.2 },
})
