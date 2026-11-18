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
return MeleeFactory.new("basic-melee_bo-staff", {
	Duration = 0.8,
	Reach = 8.5,
	DrawDelay = 0.3,
	SheatheDelay = 0.25,
	Props = {
		{
			Limb = "RightHand",
			-- a cylinder lies along its x axis, the staff runs past the hand from back to front
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4.5, 0.2, 0.2),
			Offset = CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(0, 0, 0.9),
			Color = BrickColor.new("Smoky grey").Color,
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = Vector3.new(1.5, 1.5, 5.5),
			Offset = CFrame.new(0, 0, -0.9),
		},
	},
	SwingSound = "Slash",
})
