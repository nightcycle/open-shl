--!strict
-- Services
-- Packages
-- Modules
local GunFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Gun")
-- Types
-- Constants
-- of the hand from the gun: the barrel runs on along the arm
local GRIP = CFrame.new(0, -0.5, -0.3) * CFrame.Angles(math.pi - math.pi / 20, 0, 0)
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new("ranged_handgun", {
	Shot = {
		ReleaseDelay = 0.05,
		Duration = 0.55,
		Limb = "RightHand",
		-- the far end of the part that carries the gun, a little past its barrel
		Offset = GRIP:Inverse() * Vector3.new(0, 1.7, 0),
		Speed = 160,
		Lifetime = 10,
		Size = Vector3.new(0.2, 0.2, 0.6),
		Color = BrickColor.new("Dark stone grey").Color,
		-- a bullet is too fast to be seen
		IsHidden = true,
		LaunchSound = "GunShot",
	},
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.4, 3.4, 0.8),
			Offset = GRIP,
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Handgun",
			MeshScale = Vector3.new(1.25, 1.25, 1.25),
		},
	},
})
