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
return MeleeFactory.new("basic-melee_hammer", {
	Duration = 0.8,
	Reach = 8,
	DrawDelay = 0.3,
	SheatheDelay = 0.25,
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.2, 4.5, 0.2),
			Offset = CFrame.new(0.15, 0, -1) * CFrame.Angles(0, math.pi, math.pi / 2),
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Hammer",
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			-- taller than it's wide: the head sticks out above + below the hand
			Size = Vector3.new(1.5, 2.5, 4),
			Offset = CFrame.new(0, 0, -1.5),
		},
	},
	SwingSound = "Slash",
})
