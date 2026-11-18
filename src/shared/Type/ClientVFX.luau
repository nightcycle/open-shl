--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Components
-- Hooks
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type SoundKey = VFXAssetDefinition.SoundKey
type AnimationKey = VFXAssetDefinition.AnimationKey
type MeshKey = VFXAssetDefinition.MeshKey

-- the props of every client effect. the ones a player's own machine may show to others are checked by the server
-- before they're passed on, so their validators are as tight as the effect allows
local Types = {}

local isFiniteVector3 = AbilityType.FiniteVector3
-- no side of a part an effect makes is longer than this
local MAX_SIZE = 16
local isSize = function(value: unknown): (boolean, string?)
	local success, msg = isFiniteVector3(value)
	if not success then
		return false, msg
	end
	local size = value :: Vector3
	if math.min(size.X, size.Y, size.Z) <= 0 or math.max(size.X, size.Y, size.Z) > MAX_SIZE then
		return false, `a size within {MAX_SIZE} studs expected, got {size}`
	end
	return true
end

-- held on the avatar until it's stopped
export type Animation = {
	Animation: AnimationKey,
	FadeTime: number?,
	Speed: number?,
}
Types.Animation = Type.strictInterface({
	Animation = VFXAssetDefinition.AnimationKey,
	FadeTime = Type.optional(Type.numberConstrained(0, 2)),
	Speed = Type.optional(Type.numberConstrained(0.1, 4)),
})

-- played once on the avatar from start to end
export type AnimationOnce = Animation
Types.AnimationOnce = Types.Animation

-- played once from the avatar
export type Sound = {
	Sound: SoundKey,
}
Types.Sound = Type.strictInterface({
	Sound = VFXAssetDefinition.SoundKey,
})

-- looped from the avatar until it's stopped
export type SoundLoop = Sound
Types.SoundLoop = Types.Sound

-- a part held by a limb of the avatar
export type Prop = {
	Limb: string, -- the name of the part of the avatar it's welded to
	Size: Vector3,
	Offset: CFrame, -- of the limb from the prop
	Color: Color3,
	Material: Enum.Material?,
	Mesh: MeshKey?,
}
Types.Prop = Type.strictInterface({
	Limb = Type.string,
	Size = isSize,
	Offset = Type.CFrame,
	Color = Type.Color3,
	Material = Type.optional(Type.enum(Enum.Material)),
	Mesh = Type.optional(VFXAssetDefinition.MeshKey),
})

-- a glowing shot on its way through the world
export type Bolt = {
	Origin: Vector3,
	Direction: Vector3,
	Speed: number,
	Lifetime: number,
	Size: Vector3,
	Color: Color3,
	FireSize: number?, -- of the flame it trails, none without
	OnHit: ((result: RaycastResult) -> ())?, -- only ever set by the machine that shot it
}
Types.Bolt = Type.strictInterface({
	Origin = isFiniteVector3,
	Direction = isFiniteVector3,
	Speed = Type.numberPositive,
	Lifetime = Type.numberPositive,
	Size = isSize,
	Color = Type.Color3,
	FireSize = Type.optional(Type.numberConstrained(0, 30)),
	OnHit = Type.optional(Type.callback),
})

-- holds the avatar in the air, turned to where its player points
export type Hover = {
	Height: number, -- studs it rises as it takes off
}
Types.Hover = Type.strictInterface({
	Height = Type.number,
})

-- pulls a hovering avatar to where its player points
export type Thrust = {
	Power: number, -- studs ahead of the avatar it's pulled to
}
Types.Thrust = Type.strictInterface({
	Power = Type.numberPositive,
})

-- the "not enough energy" warning of the hud
export type EnergyWarning = {}
Types.EnergyWarning = Type.strictInterface({})

return Types
