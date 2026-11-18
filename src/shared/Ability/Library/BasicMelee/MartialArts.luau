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
-- around a fist or a foot, there's nothing in them
local HITBOX_SIZE = Vector3.new(2, 2, 2)
local CONFIG: MeleeFactory.Config = {
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
}
-- every fist + foot of shl3 counts, each no bigger than itself + with a ribbon across it
local SHL3_LIMBS = { "RightHand", "LeftHand", "RightFoot", "LeftFoot" }
local SHL3_HITBOX_SIZE = Vector3.one
-- what the ribbons are drawn in unless the character has a color for the ability
local SHL3_COLOR = Color3.fromRGB(161, 161, 161)
-- Variables
-- References
-- Private Functions
-- Class
-- the moves are the same in every game, what they come to isn't
return MeleeFactory.new(
	"basic-melee_martial-arts",
	GameDefinition.tune(CONFIG, {
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 0.8
			-- a fifth of a second into the move it starts to count, the first one it runs into is all it hits
			config.SwingDelay = 0.2
			config.MaxTargets = 1
			local hitboxes: { MeleeFactory.Hitbox } = {}
			local streaks: { ClientVFXType.Streak } = {}
			for _, limb in SHL3_LIMBS do
				table.insert(hitboxes, {
					Limb = limb,
					Size = SHL3_HITBOX_SIZE,
					Offset = CFrame.identity,
				})
				table.insert(streaks, {
					Limb = limb,
					From = Vector3.new(0.5, 0, -0.1),
					To = Vector3.new(-0.5, 0, 0.1),
					Lifetime = 0.1,
					Transparency = 0.75,
					Color = SHL3_COLOR,
				})
			end
			config.Hitboxes = hitboxes
			config.Streaks = streaks
			return config
		end),
	})
)
