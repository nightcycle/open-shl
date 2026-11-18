--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new("basic-melee_jungle-knife", {
	Duration = 0.8,
	Reach = 7.5,
	DrawDelay = 0.3,
	SheatheDelay = 0.25,
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.4, 0.2, 4),
			Offset = CFrame.new(0, -0.9, 0) * CFrame.Angles(math.pi / 2, math.pi, math.pi):Inverse(),
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Knife",
			MeshScale = Vector3.one * 0.8,
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = Vector3.new(1.5, 1.5, 3.5),
			Offset = CFrame.new(0, 0, -1.35),
		},
	},
	DrawSound = "Unsheath",
	SheatheSound = "Sheath",
	SwingSound = "Slash",
})
