--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
-- Constants
-- around a fist or a foot, there's nothing in them
local HITBOX_SIZE = Vector3.new(2, 2, 2)
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new("basic-melee_martial-arts", {
	Duration = 0.8,
	Reach = 6,
	Props = {},
	-- whichever of them the move that's picked throws, all three count
	Hitboxes = {
		{
			Limb = "LeftHand",
			Size = HITBOX_SIZE,
			Offset = CFrame.identity,
		},
		{
			Limb = "RightHand",
			Size = HITBOX_SIZE,
			Offset = CFrame.identity,
		},
		{
			Limb = "RightFoot",
			Size = HITBOX_SIZE,
			Offset = CFrame.identity,
		},
	},
	SwingSound = "Slash",
})
