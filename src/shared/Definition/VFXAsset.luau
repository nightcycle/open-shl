--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
-- an effect names what it plays by key rather than by url, so nothing a client sends can make others load
-- something the game doesn't ship
export type SoundKey =
	"Boom"
	| "Bow"
	| "ForceWhoosh"
	| "GunShot"
	| "Impact"
	| "Morph"
	| "MorphReset"
	| "PewPew"
	| "Platforming"
	| "PortalShot"
	| "Sheath"
	| "Shock"
	| "Slash"
	| "Transwarp"
	| "Unsheath"
	| "WindGust"
	| "Wind"
export type SoundDefinition = {
	Url: string,
	Volume: number,
	PlaybackSpeed: number,
}
export type AnimationKey =
	"KnifeSlash"
	| "KnifeJab"
	| "Sheathing"
	| "RightSlash"
	| "LeftSlash"
	| "ClawSheathing"
	| "PowerPunch"
	| "Strike"
	| "RightFootKick"
	| "ForcePush"
	| "ForceExplosion"
	| "IceSpin"
	| "PowerShot"
	| "HeadShot"
	| "GunShooting"
	| "GunHolding"
	| "BowShooting"
	| "BowHolding"
	| "WallClimbing"
	| "FlightIdle"
	| "FlightMovement"
export type AnimationDefinition = {
	Url: string,
	Length: number, -- seconds until whatever it's the wind-up of is over
}
export type MeshKey =
	"Sword"
	| "ThrowingStar"
	| "Claw"
	| "Hammer"
	| "Katana"
	| "Knife"
	| "Trident"
	| "Rifle"
	| "Handgun"
	| "Bow"
	| "Arrow"
	| "Icicle"
export type MeshDefinition = {
	MeshUrl: string,
	TextureUrl: string,
}
export type ParticleKey = "LightningLeft" | "LightningRight" | "Tornado"
-- how an emitter gives off one kind of particle
export type ParticleDefinition = {
	TextureUrl: string,
	Rate: number, -- a second
	Lifetime: NumberRange,
	Size: number,
	Rotation: NumberRange,
	Speed: number,
	LightEmission: number,
	IsLockedToPart: boolean, -- they go where what gives them off goes
	Color: ColorSequence?, -- over their life, white without
	EndSize: number?, -- what they've grown or shrunk to by the end of their life, the size they start at without
	RotationSpeed: number?, -- degrees a second they turn at, they don't without
	SpreadAngle: number?, -- degrees they're given off at either side of straight up, none without
	Transparency: NumberSequence?, -- over their life, they're there until they're gone without
	VelocityInheritance: number?, -- how much of the pace of what gives them off they set out with, none without
}
export type DecalKey = "PsychicWave" | "Shockwave"
export type DecalDefinition = {
	TextureUrl: string,
}
-- Constants
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	Boom = { Url = "rbxasset://sounds/Rocket shot.wav", Volume = 0.7, PlaybackSpeed = 1 },
	Bow = { Url = "rbxassetid://173979241", Volume = 0.5, PlaybackSpeed = 1 },
	ForceWhoosh = { Url = "rbxassetid://580313487", Volume = 1, PlaybackSpeed = 1 },
	GunShot = { Url = "rbxassetid://356911785", Volume = 0.25, PlaybackSpeed = 1 },
	Impact = { Url = "rbxassetid://177172187", Volume = 1, PlaybackSpeed = 1 },
	Morph = { Url = "rbxassetid://48579482", Volume = 0.55, PlaybackSpeed = 1 },
	MorphReset = { Url = "rbxassetid://48579638", Volume = 0.55, PlaybackSpeed = 1 },
	PewPew = { Url = "rbxassetid://13775494", Volume = 1.2, PlaybackSpeed = 0.6 },
	Platforming = { Url = "rbxassetid://34315534", Volume = 1, PlaybackSpeed = 1 },
	PortalShot = { Url = "rbxassetid://34320952", Volume = 1, PlaybackSpeed = 1 },
	Sheath = { Url = "rbxassetid://580372069", Volume = 1, PlaybackSpeed = 1 },
	Shock = { Url = "rbxassetid://10756118", Volume = 1, PlaybackSpeed = 1 },
	Slash = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.5, PlaybackSpeed = 0.9 },
	Transwarp = { Url = "rbxassetid://35275769", Volume = 0.7, PlaybackSpeed = 4 },
	Unsheath = { Url = "rbxassetid://580370973", Volume = 1, PlaybackSpeed = 1 },
	WindGust = { Url = "rbxassetid://582407217", Volume = 0.5, PlaybackSpeed = 1 },
	Wind = { Url = "rbxassetid://362395087", Volume = 0.3, PlaybackSpeed = 0.8 },
}
TableUtil.deepFreeze(SOUNDS)
local ANIMATIONS: { [AnimationKey]: AnimationDefinition } = {
	KnifeSlash = { Url = "rbxassetid://580441242", Length = 0.8 },
	KnifeJab = { Url = "rbxassetid://580438782", Length = 0.8 },
	Sheathing = { Url = "rbxassetid://580434436", Length = 0.8 },
	RightSlash = { Url = "rbxassetid://580402239", Length = 0.8 },
	LeftSlash = { Url = "rbxassetid://580408411", Length = 0.8 },
	ClawSheathing = { Url = "rbxassetid://580413960", Length = 0.8 },
	PowerPunch = { Url = "rbxassetid://580665102", Length = 0.8 },
	Strike = { Url = "rbxassetid://580683034", Length = 0.8 },
	RightFootKick = { Url = "rbxassetid://580717982", Length = 0.8 },
	ForcePush = { Url = "rbxassetid://580087215", Length = 1 },
	ForceExplosion = { Url = "rbxassetid://583352411", Length = 2 },
	IceSpin = { Url = "rbxassetid://582036597", Length = 2 },
	PowerShot = { Url = "rbxassetid://584892686", Length = 2 },
	HeadShot = { Url = "rbxassetid://584939993", Length = 0.5 },
	GunShooting = { Url = "rbxassetid://586915698", Length = 2 },
	GunHolding = { Url = "rbxassetid://586909830", Length = 4 },
	BowShooting = { Url = "rbxassetid://910052477", Length = 2 },
	BowHolding = { Url = "rbxassetid://910048046", Length = 0.5 },
	WallClimbing = { Url = "rbxassetid://599890877", Length = 0.6 },
	FlightIdle = { Url = "rbxassetid://596610664", Length = 4.5 },
	FlightMovement = { Url = "rbxassetid://596620930", Length = 4.5 },
}
TableUtil.deepFreeze(ANIMATIONS)
local MESHES: { [MeshKey]: MeshDefinition } = {
	Sword = { MeshUrl = "rbxasset://fonts/sword.mesh", TextureUrl = "" },
	ThrowingStar = { MeshUrl = "rbxassetid://11376946", TextureUrl = "" },
	Claw = { MeshUrl = "rbxassetid://10681506", TextureUrl = "" },
	Hammer = { MeshUrl = "rbxassetid://12592754", TextureUrl = "rbxassetid://12592745" },
	Katana = { MeshUrl = "rbxassetid://11442510", TextureUrl = "" },
	Knife = { MeshUrl = "rbxassetid://121944778", TextureUrl = "" },
	Trident = { MeshUrl = "rbxassetid://53926151", TextureUrl = "" },
	Rifle = { MeshUrl = "rbxassetid://72012671", TextureUrl = "rbxassetid://72012605" },
	Handgun = { MeshUrl = "rbxassetid://72012879", TextureUrl = "rbxassetid://72012859" },
	Bow = { MeshUrl = "rbxassetid://55709693", TextureUrl = "" },
	Arrow = { MeshUrl = "rbxassetid://1036682", TextureUrl = "" },
	Icicle = { MeshUrl = "rbxassetid://20518365", TextureUrl = "rbxassetid://19287687" },
}
TableUtil.deepFreeze(MESHES)
local PARTICLES: { [ParticleKey]: ParticleDefinition } = {
	LightningLeft = {
		TextureUrl = "rbxassetid://280294650",
		Rate = 30,
		Lifetime = NumberRange.new(0.1, 0.2),
		Size = 2,
		Rotation = NumberRange.new(-100, -1),
		Speed = 0,
		LightEmission = 1,
		IsLockedToPart = true,
	},
	LightningRight = {
		TextureUrl = "rbxassetid://280294638",
		Rate = 30,
		Lifetime = NumberRange.new(0.1, 0.2),
		Size = 2,
		Rotation = NumberRange.new(1, 100),
		Speed = 0,
		LightEmission = 1,
		IsLockedToPart = true,
	},
	Tornado = {
		TextureUrl = "rbxasset://textures/particles/smoke_main.dds",
		Rate = 100,
		Lifetime = NumberRange.new(1.5, 2.5),
		Size = 8.1875,
		Rotation = NumberRange.new(0),
		Speed = 20,
		LightEmission = 0,
		IsLockedToPart = true,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0.34509805, 0.37647063, 0.3803922)),
			ColorSequenceKeypoint.new(0.75374377, Color3.new(0.5684839, 0.5891553, 0.5917393)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		EndSize = 10,
		RotationSpeed = 40,
		SpreadAngle = 40,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.9110429, 0.049382687),
			NumberSequenceKeypoint.new(1, 1),
		}),
		VelocityInheritance = 2,
	},
}
TableUtil.deepFreeze(PARTICLES)
local DECALS: { [DecalKey]: DecalDefinition } = {
	PsychicWave = { TextureUrl = "rbxassetid://580331200" },
	Shockwave = { TextureUrl = "rbxassetid://1280730" },
}
TableUtil.deepFreeze(DECALS)
-- Variables
-- References
-- Private Functions
local function isKey(definitions: { [any]: any }): (value: unknown) -> (boolean, string?)
	local keys: { string } = {}
	for key in definitions do
		table.insert(keys, key)
	end
	return Type.literal(table.unpack(keys))
end
-- Class
local Module = {}

Module.SoundKey = isKey(SOUNDS)
Module.AnimationKey = isKey(ANIMATIONS)
Module.MeshKey = isKey(MESHES)
Module.ParticleKey = isKey(PARTICLES)
Module.DecalKey = isKey(DECALS)

Module.getSound = function(key: SoundKey): SoundDefinition
	return SOUNDS[key]
end

Module.getAnimation = function(key: AnimationKey): AnimationDefinition
	return ANIMATIONS[key]
end

Module.getMesh = function(key: MeshKey): MeshDefinition
	return MESHES[key]
end

Module.getParticle = function(key: ParticleKey): ParticleDefinition
	return PARTICLES[key]
end

Module.getDecal = function(key: DecalKey): DecalDefinition
	return DECALS[key]
end

return Module
