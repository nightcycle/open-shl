--!strict
-- Services
-- Packages
-- Modules
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
type MeshKey = VFXAssetDefinition.MeshKey
type SoundKey = VFXAssetDefinition.SoundKey
-- what tells one thing to eat or drink from the next. how long a use takes + how long it keeps the next one off are
-- on the row of the prop
export type Config = {
	Size: Vector3,
	Mesh: MeshKey,
	MeshScale: Vector3?,
	RestOffset: CFrame, -- of the hand from it while it's out in front
	UseOffset: CFrame, -- of the hand from it for as long as a use takes: up at the mouth
	DrawSound: SoundKey?, -- heard as it's got out, it comes out quietly without
	UseSound: SoundKey, -- heard as a use starts
	Health: number?, -- what a use that ran its length gives back, nothing without
}
-- what both halves of something to eat or drink have to agree on
export type Consumable = {
	Prop: PropDefinition.PropDefinition,
	Rest: ClientVFXType.Prop,
	Use: ClientVFXType.Prop,
	HoldAnimation: AnimationKey,
	DrawSound: ClientVFXType.Sound?,
	UseSound: ClientVFXType.Sound,
	Health: number?,
}
-- Constants
-- the arm out in front, what a hand that holds anything used to do by itself. nothing moves the arm for a use: the
-- old tools moved their grip, so it's the thing in the hand that goes up to the mouth
local HOLD_ANIMATION: AnimationKey = "GunHolding"
-- the mesh is drawn by its texture, the part under it never shows
local COLOR = Color3.new(1, 1, 1)
-- Variables
-- References
-- Private Functions
local function newLook(config: Config, offset: CFrame): ClientVFXType.Prop
	return table.freeze({
		Limb = "RightHand",
		Size = config.Size,
		Offset = offset,
		Color = COLOR,
		Mesh = config.Mesh,
		MeshScale = config.MeshScale,
	})
end

local function newSound(sound: SoundKey): ClientVFXType.Sound
	return table.freeze({ Sound = sound })
end
-- Class
local Module = {}

-- something to eat or drink: a click starts a use of the length its row says, for that long it's at the mouth instead
-- of out in front, a sound plays as it starts + whatever it gives comes at its end. a click during a use is dropped,
-- + a use that's cut short gives nothing
Module.new = function(id: string, config: Config): Consumable
	local definitionRes = PropDefinition.get(id)
	assert(definitionRes.IsOk, `no prop is registered as "{id}"`)
	assert(definitionRes.Value.Use, `"{id}" is eaten or drunk a use at a time, its row says how long one takes`)
	return table.freeze({
		Prop = definitionRes.Value,
		Rest = newLook(config, config.RestOffset),
		Use = newLook(config, config.UseOffset),
		HoldAnimation = HOLD_ANIMATION,
		DrawSound = if config.DrawSound then newSound(config.DrawSound) else nil,
		UseSound = newSound(config.UseSound),
		Health = config.Health,
	})
end

return Module
