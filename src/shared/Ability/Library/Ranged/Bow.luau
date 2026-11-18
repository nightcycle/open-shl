--!strict
-- Services
-- Packages
-- Modules
local GunFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Gun")
-- Types
-- Constants
-- of the hand from the bow
local GRIP = CFrame.new(-0.325, 0.35, 0) * CFrame.Angles(-math.pi + math.pi / 20, 0, math.rad(-110)):Inverse()
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new("ranged_bow", {
	Shot = {
		-- the string is drawn first
		ReleaseDelay = 0.25,
		Duration = 0.7,
		Limb = "RightHand",
		-- an end of the bow
		Offset = GRIP:Inverse() * Vector3.new(0, 1.7, 0),
		Speed = 175,
		Lifetime = 8,
		Size = Vector3.new(0.2, 0.2, 2.5),
		Color = BrickColor.new("Really black").Color,
		Mesh = "Arrow",
		MeshScale = Vector3.new(0.6, 0.25, 1),
		-- the arrow is modelled lying across the way it's headed
		Turn = CFrame.Angles(0, math.rad(90), 0),
	},
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.4, 3.4, 0.8),
			Offset = GRIP,
			Color = BrickColor.new("Really black").Color,
			Mesh = "Bow",
			MeshScale = Vector3.new(1.5, 1.5, 1.5),
		},
	},
	HasColoredProps = true,
})
