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
local HITBOX_SIZE = Vector3.new(1.5, 1.5, 5)
local HITBOX_OFFSET = CFrame.new(0, 0, -2)
-- the blades of shl3 are a little longer + held further up, each is its own hit box
local SHL3_SIZE = Vector3.new(0.5, 0.5, 4.5)
-- what they're drawn in unless the character has a color for the ability
local SHL3_COLOR = Color3.fromRGB(161, 161, 161)
-- how a hand holds its blade, both the same way
local SHL3_OFFSET = CFrame.new(0.1, 0, -1.6) * CFrame.Angles(0, math.rad(180), math.rad(90))
-- Variables
-- References
-- Private Functions
-- the two hands hold the same blade the same way
local function newKatana(limb: string): ClientVFXType.Prop
	return {
		Limb = limb,
		Size = Vector3.new(0.4, 0.2, 4),
		Offset = CFrame.new(0, 0, -1.5) * CFrame.Angles(0, math.pi, math.pi / 2):Inverse(),
		Color = BrickColor.new("Smoky grey").Color,
		Mesh = "Katana",
		MeshScale = Vector3.one * 1.3,
	}
end
-- Class
local base: MeleeFactory.Config = {
	Duration = 0.8,
	Reach = 9,
	DrawDelay = 0.6,
	SheatheDelay = 0.6,
	Props = { newKatana("LeftHand"), newKatana("RightHand") },
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

-- what's swung is the same in every game, how it's held + what a swing comes to isn't
return MeleeFactory.new(
	"basic-melee_dual-katana",
	GameDefinition.tune(base, {
		shl3 = FreezeUtil.delta(base, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 0.8
			-- a fifth of a second into the swing they start to count, the first one they run into is all they hit
			config.SwingDelay = 0.2
			config.MaxTargets = 1
			-- they're drawn in half the time + without a sound
			config.DrawDelay = 0.3
			config.SheatheDelay = 0.3
			config.DrawSound = nil
			config.SheatheSound = nil
			local props: { ClientVFXType.Prop } = {}
			local hitboxes: { MeleeFactory.Hitbox } = {}
			local streaks: { ClientVFXType.Streak } = {}
			for _, limb in { "RightHand", "LeftHand" } do
				table.insert(props, {
					Limb = limb,
					Size = SHL3_SIZE,
					Offset = SHL3_OFFSET,
					Color = SHL3_COLOR,
					Material = Enum.Material.SmoothPlastic,
					Mesh = "Katana",
					MeshScale = Vector3.one * 1.45,
					MeshOffset = Vector3.new(0, 0, -0.2),
				})
				-- a box is placed by where it is off the limb, a prop by where the limb is off it
				table.insert(hitboxes, {
					Limb = limb,
					Size = SHL3_SIZE,
					Offset = SHL3_OFFSET:Inverse(),
				})
				-- along the blade, from tip to guard
				table.insert(streaks, {
					Limb = limb,
					From = Vector3.new(0, 0, 2.1),
					To = Vector3.new(0, 0, -1.7),
					Offset = SHL3_OFFSET,
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
