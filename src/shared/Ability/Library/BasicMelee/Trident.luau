--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
-- Constants
-- how far the trident is tipped out of the line of the hand, the box that's swept is tipped along with it
local TILT = 0.16 * math.pi
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new("basic-melee_trident", {
	Duration = 0.8,
	Reach = 9.5,
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.2, 4.5, 0.2),
			Offset = CFrame.new(0.15, 0, -1.5) * CFrame.Angles(0, math.pi + TILT, math.pi / 2),
			Color = BrickColor.new("Medium stone grey").Color,
			Mesh = "Trident",
			MeshScale = Vector3.one * 1.25,
			MeshOffset = Vector3.new(0, 0, -0.3),
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = Vector3.new(1.5, 2, 7),
			Offset = CFrame.Angles(-TILT, 0, 0) * CFrame.new(0, 0, -1.7),
		},
	},
	SwingSound = "Slash",
})
