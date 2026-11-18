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
return MeleeFactory.new("basic-melee_sword", {
	Duration = 0.8,
	Reach = 9,
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.2, 4.5, 0.2),
			Offset = CFrame.new(0.15, 0, -1.5) * CFrame.Angles(0, math.pi, math.pi / 2),
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Sword",
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = Vector3.new(1.5, 1.5, 5),
			Offset = CFrame.new(0, 0, -2),
		},
	},
	SwingSound = "Slash",
})
