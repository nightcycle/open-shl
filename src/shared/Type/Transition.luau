--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Types
local Types = {}

export type EffectDefinition =
	{
		Type: "Fire",
		StartDelay: number, -- seconds after the animation starts
		EmitDuration: number, -- seconds it emits for
		Lifetime: number, -- seconds until it is removed, what it emitted goes with it
		Offset: Vector3, -- from the root part
		Color: Color3,
		SecondaryColor: Color3,
		Heat: number,
		Size: number,
	}
	| {
		Type: "Smoke",
		StartDelay: number, -- seconds after the animation starts
		EmitDuration: number, -- seconds it emits for
		Lifetime: number, -- seconds until it is removed, what it emitted goes with it
		Offset: Vector3, -- from the root part
		Color: Color3,
		Opacity: number,
		RiseVelocity: number,
		Size: number,
	}
Types.EffectDefinition = Type.union(
	Type.strictInterface({
		Type = Type.literal("Fire"),
		StartDelay = Type.number,
		EmitDuration = Type.number,
		Lifetime = Type.number,
		Offset = Type.Vector3,
		Color = Type.Color3,
		SecondaryColor = Type.Color3,
		Heat = Type.number,
		Size = Type.number,
	}),
	Type.strictInterface({
		Type = Type.literal("Smoke"),
		StartDelay = Type.number,
		EmitDuration = Type.number,
		Lifetime = Type.number,
		Offset = Type.Vector3,
		Color = Type.Color3,
		Opacity = Type.number,
		RiseVelocity = Type.number,
		Size = Type.number,
	})
)

export type TransformationDefinition = {
	Style: PseudoEnum.TransformationStyle,
	Name: string,
	AnimationId: string?, -- left out, nothing is played: the swap is timed as if one started
	AnimationLength: number,
	SwapDelay: number, -- seconds after the animation starts that the server changes the identity
	LockDuration: number, -- seconds after the animation starts that another swap can begin
	FreezeDuration: number?, -- seconds the character can't walk for, nil leaves them free to move
	Effect: EffectDefinition?,
}
Types.TransformationDefinition = Type.strictInterface({
	Style = Type.literal(table.unpack(PseudoEnum.getEnumItems("TransformationStyle"))),
	Name = Type.string,
	AnimationId = Type.optional(Type.string),
	AnimationLength = Type.number,
	SwapDelay = Type.number,
	LockDuration = Type.number,
	FreezeDuration = Type.optional(Type.number),
	Effect = Type.optional(Types.EffectDefinition),
})

export type DeathDefinition = {
	Style: PseudoEnum.DeathStyle,
	Name: string,
	AnimationId: string?, -- left out, nothing is played
	-- what becomes of the body beside that. limp, it hangs loose from its joints. left out, it's held as it is
	Motion: "Limp"?,
	AnimationLength: number,
	RespawnDelay: number, -- seconds after the animation starts that the server moves the character to a spawn
	FreezeDuration: number, -- seconds the character can't walk or jump for
}
Types.DeathDefinition = Type.strictInterface({
	Style = Type.literal(table.unpack(PseudoEnum.getEnumItems("DeathStyle"))),
	Name = Type.string,
	AnimationId = Type.optional(Type.string),
	Motion = Type.optional(Type.literal("Limp")),
	AnimationLength = Type.number,
	RespawnDelay = Type.number,
	FreezeDuration = Type.number,
})

-- what a game's characters swap + die by. a style it has no row for is one its editor has no page to pick
export type TransitionCatalogue = {
	Transformations: { [PseudoEnum.TransformationStyle]: TransformationDefinition },
	Deaths: { [PseudoEnum.DeathStyle]: DeathDefinition },
}
Types.TransitionCatalogue = Type.strictInterface({
	Transformations = Type.map(
		Type.literal(table.unpack(PseudoEnum.getEnumItems("TransformationStyle"))),
		Types.TransformationDefinition
	),
	Deaths = Type.map(Type.literal(table.unpack(PseudoEnum.getEnumItems("DeathStyle"))), Types.DeathDefinition),
})

return Types
