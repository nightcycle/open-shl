--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
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
local CONFIG: MeleeFactory.Config = {
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
}
-- the claws of shl3 are shorter + sit across the back of the hand, each is its own hit box
local SHL3_SIZE = Vector3.new(0.2, 0.5, 1.5)
-- what they're drawn in unless the character has a color for the ability
local SHL3_COLOR = Color3.fromRGB(161, 161, 161)
-- how a hand holds its claw, the two mirror each other
local SHL3_OFFSETS: { [string]: CFrame } = {
	RightHand = CFrame.new(-0.4, 0, -0.8) * CFrame.Angles(math.rad(-90), 0, 0),
	LeftHand = CFrame.new(-0.4, 0, -0.8) * CFrame.Angles(math.rad(-90), math.rad(180), 0),
}
-- Variables
-- References
-- Private Functions
-- Class
-- what's swung is the same in every game, how it's held + what a swing comes to isn't
return MeleeFactory.new(
	"basic-melee_claws",
	GameDefinition.tune(CONFIG, {
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 0.8
			-- a fifth of a second into the swing they start to count, the first one they run into is all they hit
			config.SwingDelay = 0.2
			config.MaxTargets = 1
			-- they're there + gone a moment after the tool is, without a slide or a sound
			config.DrawDelay = 0.3
			config.SheatheDelay = 0.3
			config.DrawSound = nil
			config.SheatheSound = nil
			local props: { ClientVFXType.Prop } = {}
			local hitboxes: { MeleeFactory.Hitbox } = {}
			local streaks: { ClientVFXType.Streak } = {}
			for _, limb in { "RightHand", "LeftHand" } do
				local offset = SHL3_OFFSETS[limb]
				table.insert(props, {
					Limb = limb,
					Size = SHL3_SIZE,
					Offset = offset,
					Color = SHL3_COLOR,
					Material = Enum.Material.SmoothPlastic,
					Mesh = "Claw",
					MeshScale = Vector3.new(0.8, 1, 0.6),
					MeshOffset = Vector3.new(0, 0, -0.2),
				})
				-- a box is placed by where it is off the limb, a prop by where the limb is off it
				table.insert(hitboxes, {
					Limb = limb,
					Size = SHL3_SIZE,
					Offset = offset:Inverse(),
				})
				-- along the claw, from tip to wrist
				table.insert(streaks, {
					Limb = limb,
					From = Vector3.new(0, 0, -0.6),
					To = Vector3.new(0, 0, 0.6),
					Offset = offset,
					Lifetime = 0.07,
					Transparency = 0.75,
					Color = SHL3_COLOR,
				})
			end
			config.Props = props
			config.Hitboxes = hitboxes
			config.Streaks = streaks
			return config
		end),
	})
)
