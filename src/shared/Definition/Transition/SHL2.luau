--!strict
-- Services
-- Packages
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local TransitionType = require("@game/ReplicatedStorage/Shared/Type/Transition")
type TransitionCatalogue = TransitionType.TransitionCatalogue
-- Constants
local ASCENSION_ANIMATION_ID = Animation["shl-2"].transition["ascension.rbxm"]
local SPIN_ANIMATION_ID = Animation["shl-2"].transition["spin.rbxm"]
local FIRE_ANIMATION_ID = Animation["shl-2"].transition["fire.rbxm"]
local SMOKE_ANIMATION_ID = Animation["shl-2"].transition["smoke.rbxm"]
local FALL_BACKWARD_ANIMATION_ID = Animation["shl-2"].transition["fall-backward.rbxm"]
local FALL_FORWARD_ANIMATION_ID = Animation.core.transition["fall-forward.rbxm"]
local SWAP_COOLDOWN = 1
local CATALOGUE: TransitionCatalogue = {
	-- the delays are timed so the costume changes behind the animation + its effect
	Transformations = {
		Ascension = {
			Style = PseudoEnum.TransformationStyle.Ascension,
			Name = "Ascension",
			AnimationId = ASCENSION_ANIMATION_ID,
			AnimationLength = 3,
			SwapDelay = 1.5,
			LockDuration = 1.5 + SWAP_COOLDOWN,
		},
		-- the one every character starts out with
		Spin = {
			Style = PseudoEnum.TransformationStyle.Spin,
			Name = "Spin",
			AnimationId = SPIN_ANIMATION_ID,
			AnimationLength = 1,
			SwapDelay = 0.4,
			LockDuration = 0.4 + SWAP_COOLDOWN,
		},
		Fire = {
			Style = PseudoEnum.TransformationStyle.Fire,
			Name = "Fire",
			AnimationId = FIRE_ANIMATION_ID,
			AnimationLength = 2,
			SwapDelay = 0.45,
			LockDuration = 0.45 + SWAP_COOLDOWN,
			FreezeDuration = 1.8,
			Effect = {
				Type = "Fire",
				StartDelay = 0.3,
				EmitDuration = 0.6,
				Lifetime = 1.6,
				Offset = Vector3.zero,
				Color = Color3.fromRGB(236, 139, 70),
				SecondaryColor = Color3.fromRGB(139, 80, 55),
				Heat = 9,
				Size = 8,
			},
		},
		Smoke = {
			Style = PseudoEnum.TransformationStyle.Smoke,
			Name = "Smoke",
			AnimationId = SMOKE_ANIMATION_ID,
			AnimationLength = 0.8,
			SwapDelay = 1.5,
			LockDuration = 1.5 + SWAP_COOLDOWN,
			FreezeDuration = 1.2,
			Effect = {
				Type = "Smoke",
				StartDelay = 0,
				EmitDuration = 1,
				Lifetime = 2,
				Offset = Vector3.new(0, -2, 0),
				Color = Color3.new(),
				Opacity = 1,
				RiseVelocity = 7,
				Size = 4,
			},
		},
	},
	Deaths = {
		FallBackward = {
			Style = PseudoEnum.DeathStyle.FallBackward,
			Name = "Fall Backwards",
			AnimationId = FALL_BACKWARD_ANIMATION_ID,
			AnimationLength = 3,
			RespawnDelay = 3,
			FreezeDuration = 3,
		},
		FallForward = {
			Style = PseudoEnum.DeathStyle.FallForward,
			Name = "Fall Forwards",
			AnimationId = FALL_FORWARD_ANIMATION_ID,
			AnimationLength = 3,
			RespawnDelay = 3,
			FreezeDuration = 3,
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
