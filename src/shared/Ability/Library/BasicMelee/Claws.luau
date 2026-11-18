--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
-- Constants
local SIZE = Vector3.new(0.2, 0.4, 2)
local COLOR = BrickColor.new("Smoky grey").Color
-- a claw lies along the arm: all the way out it sticks out past the fingers, all the way in it's up the wrist
local OUT_OFFSET = CFrame.new(-0.3, 0, -0.5)
local IN_OFFSET = CFrame.new(-0.3, 0, 0.75)
-- the two hands mirror each other
local LEFT_TURN = CFrame.Angles(math.pi / 2, 0, math.pi):Inverse()
local RIGHT_TURN = CFrame.Angles(math.pi / 2, 0, 0):Inverse()
local SLIDE_DURATION = 0.175
local HITBOX_SIZE = Vector3.new(1.5, 2.5, 1.5)
local HITBOX_OFFSET = CFrame.new(0, -0.75, 0)
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new("basic-melee_claws", {
	Duration = 0.8,
	Reach = 7,
	Props = {
		{
			Limb = "LeftHand",
			Size = SIZE,
			Offset = OUT_OFFSET * LEFT_TURN,
			Color = COLOR,
			Mesh = "Claw",
			SlideOffset = IN_OFFSET * LEFT_TURN,
			SlideDuration = SLIDE_DURATION,
		},
		{
			Limb = "RightHand",
			Size = SIZE,
			Offset = OUT_OFFSET * RIGHT_TURN,
			Color = COLOR,
			Mesh = "Claw",
			SlideOffset = IN_OFFSET * RIGHT_TURN,
			SlideDuration = SLIDE_DURATION,
		},
	},
	Hitboxes = {
		{
			Limb = "LeftHand",
			Size = HITBOX_SIZE,
			Offset = HITBOX_OFFSET,
		},
		{
			Limb = "RightHand",
			Size = HITBOX_SIZE,
			Offset = HITBOX_OFFSET,
		},
	},
	DrawSound = "Unsheath",
	SheatheSound = "Sheath",
	SwingSound = "Slash",
})
