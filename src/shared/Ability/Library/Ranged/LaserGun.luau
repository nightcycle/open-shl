--!strict
-- Services
-- Packages
-- Modules
local GunFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Gun")
-- Types
-- Constants
-- of the hand from the rifle: the barrel runs on along the arm
local GRIP = CFrame.new(0, -0.7, -0.5) * CFrame.Angles(math.pi - math.pi / 20, 0, 0)
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new("ranged_laser-gun", {
	Shot = {
		ReleaseDelay = 0.05,
		-- it's ready again as soon as a shot is out: it fires as fast as its player clicks
		Duration = 0.05,
		Limb = "RightHand",
		-- the far end of the barrel
		Offset = GRIP:Inverse() * Vector3.new(0, 1.7, 0),
		Speed = 160,
		Lifetime = 10,
		Size = Vector3.new(0.2, 0.2, 4),
		Color = BrickColor.new("Cyan").Color,
		LaunchSound = "PewPew",
	},
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.4, 3.4, 0.8),
			Offset = GRIP,
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Rifle",
		},
	},
})
