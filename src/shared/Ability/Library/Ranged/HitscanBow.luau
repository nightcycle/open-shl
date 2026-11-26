--!strict
-- Services
-- Packages
-- Modules
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
-- Constants
-- how the hand holds the bow
local GRIP = CFrame.new(-0.25, -0.2, -0.25) * CFrame.Angles(math.rad(90), math.rad(180), math.rad(-20))
-- Variables
-- References
-- Private Functions
-- Class
-- an arrow that's there the moment it's let go: nothing flies, what's left of it sticks where it ended
return RayFactory.new("ranged_hitscan-bow", {
	-- a fifth of a second, then the second it's listed with
	Duration = 1.2,
	Limb = "RightHand",
	-- it leaves from the bow, not the wrist
	Offset = GRIP:Inverse() * Vector3.new(0, -0.6, -0.45),
	Range = 500,
	Beams = {
		-- grey whatever the suit
		{
			Thickness = 0.1,
			Transparency = 0.2,
			Lifetime = 0.07,
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(140, 140, 140),
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
			Mesh = "Bow",
			MeshScale = Vector3.new(0.55, 0.55, 0.45),
			MeshOffset = Vector3.new(-0.2, -0.17, 0.15),
			Delay = 0.3,
			Linger = 0.3,
		},
	},
	HasColoredProps = true,
	FireSound = "Bow",
	-- the arrow has a picture of its own, the color is for the day it's tinted
	Shaft = {
		Size = Vector3.new(0.2, 0.2, 2),
		Mesh = "Arrow",
		MeshOffset = Vector3.new(0.05, -0.015, 0),
		Color = Color3.new(0, 0, 0),
		IsSecondary = true,
		Lifetime = 8,
	},
})
