--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local TransitionType = require("@game/ReplicatedStorage/Shared/Type/Transition")
export type EffectDefinition = TransitionType.EffectDefinition
export type TransformationDefinition = TransitionType.TransformationDefinition
export type DeathDefinition = TransitionType.DeathDefinition
-- Constants
-- animations are owned by the old place
local ASCENSION_ANIMATION_ID = "rbxassetid://601437776"
local SPIN_ANIMATION_ID = "rbxassetid://601411837"
local FIRE_ANIMATION_ID = "rbxassetid://601430281"
local SMOKE_ANIMATION_ID = "rbxassetid://601428872"
local FALL_BACKWARD_ANIMATION_ID = "rbxassetid://601499493"
local FALL_FORWARD_ANIMATION_ID = "rbxassetid://601481878"
-- one of the two plays when a hit leaves the character standing
local FLINCH = table.freeze({
	ANIMATION_IDS = table.freeze({
		"rbxassetid://938913337",
		"rbxassetid://938919081",
	}),
	DURATION = 0.4,
})
local SWAP_COOLDOWN = 1
local DEFAULT_TRANSFORMATION_STYLE: PseudoEnum.TransformationStyle = PseudoEnum.TransformationStyle.Spin
local DEFAULT_DEATH_STYLE: PseudoEnum.DeathStyle = PseudoEnum.DeathStyle.FallForward
-- the delays are timed so the costume changes behind the animation + its effect
local TRANSFORMATIONS: { [PseudoEnum.TransformationStyle]: TransformationDefinition } = {
	Ascension = {
		Style = PseudoEnum.TransformationStyle.Ascension,
		Name = "Ascension",
		AnimationId = ASCENSION_ANIMATION_ID,
		AnimationLength = 3,
		SwapDelay = 1.5,
		LockDuration = 1.5 + SWAP_COOLDOWN,
	},
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
}
TableUtil.deepFreeze(TRANSFORMATIONS)
-- the character lies where it fell for the length of the animation, it never dies as far as roblox can tell
local DEATHS: { [PseudoEnum.DeathStyle]: DeathDefinition } = {
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
}
TableUtil.deepFreeze(DEATHS)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

for style, DEFINITION in TRANSFORMATIONS do
	assert(TransitionType.TransformationDefinition(DEFINITION))
	assert(DEFINITION.Style == style, `"{style}" transformation is filed under the wrong style`)
end
for style, DEFINITION in DEATHS do
	assert(TransitionType.DeathDefinition(DEFINITION))
	assert(DEFINITION.Style == style, `"{style}" death is filed under the wrong style`)
end

Module.DEFAULT_TRANSFORMATION_STYLE = DEFAULT_TRANSFORMATION_STYLE
Module.DEFAULT_DEATH_STYLE = DEFAULT_DEATH_STYLE
Module.FLINCH = FLINCH

Module.getTransformation = function(style: PseudoEnum.TransformationStyle?): TransformationDefinition
	return TRANSFORMATIONS[style or DEFAULT_TRANSFORMATION_STYLE]
end

Module.getDeath = function(style: PseudoEnum.DeathStyle?): DeathDefinition
	return DEATHS[style or DEFAULT_DEATH_STYLE]
end

Module.listTransformations = function(): { TransformationDefinition }
	local out: { TransformationDefinition } = {}
	for _, style: PseudoEnum.TransformationStyle in PseudoEnum.getEnumItems("TransformationStyle") do
		table.insert(out, TRANSFORMATIONS[style])
	end
	table.freeze(out)
	return out
end

Module.listDeaths = function(): { DeathDefinition }
	local out: { DeathDefinition } = {}
	for _, style: PseudoEnum.DeathStyle in PseudoEnum.getEnumItems("DeathStyle") do
		table.insert(out, DEATHS[style])
	end
	table.freeze(out)
	return out
end

return Module
