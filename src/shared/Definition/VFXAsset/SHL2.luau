--!strict
-- Services
-- Packages
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
local Audio = require("@game/ReplicatedStorage/Generated/Audio")
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local VFXAssetType = require("@game/ReplicatedStorage/Shared/Type/VFXAsset")
type SoundKey = VFXAssetType.SoundKey
type SoundDefinition = VFXAssetType.SoundDefinition
type AnimationKey = VFXAssetType.AnimationKey
type AnimationDefinition = VFXAssetType.AnimationDefinition
type MeshKey = VFXAssetType.MeshKey
type MeshDefinition = VFXAssetType.MeshDefinition
type ParticleKey = VFXAssetType.ParticleKey
type ParticleDefinition = VFXAssetType.ParticleDefinition
type DecalKey = VFXAssetType.DecalKey
type DecalDefinition = VFXAssetType.DecalDefinition
type VFXAssetCatalogue = VFXAssetType.VFXAssetCatalogue
-- Constants
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	Boom = { Url = "rbxasset://sounds/Rocket shot.wav", Volume = 0.7, PlaybackSpeed = 1 },
	Bow = { Url = Audio.ability["bow.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
	ForceWhoosh = { Url = Audio.ability["force-whoosh.ogg"], Volume = 1, PlaybackSpeed = 1 },
	GunShot = { Url = Audio.ability["gun-shot.ogg"], Volume = 0.25, PlaybackSpeed = 1 },
	Impact = { Url = Audio.ability["impact.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Morph = { Url = Audio.ability["morph.ogg"], Volume = 0.55, PlaybackSpeed = 1 },
	MorphReset = { Url = Audio.ability["morph-reset.ogg"], Volume = 0.55, PlaybackSpeed = 1 },
	PewPew = { Url = Audio.ability["pew-pew.ogg"], Volume = 1.2, PlaybackSpeed = 0.6 },
	Platforming = { Url = Audio.ability["platforming.ogg"], Volume = 1, PlaybackSpeed = 1 },
	PortalShot = { Url = Audio.ability["portal-shot.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Sheath = { Url = Audio.ability["sheath.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Shock = { Url = Audio.ability["shock.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Slash = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.5, PlaybackSpeed = 0.9 },
	Transwarp = { Url = Audio.ability["transwarp.ogg"], Volume = 0.7, PlaybackSpeed = 4 },
	Unsheath = { Url = Audio.ability["unsheath.ogg"], Volume = 1, PlaybackSpeed = 1 },
	WindGust = { Url = Audio.ability["wind-gust.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
	Wind = { Url = Audio.ability["wind.ogg"], Volume = 0.3, PlaybackSpeed = 0.8 },
}
local ANIMATIONS: { [AnimationKey]: AnimationDefinition } = {
	KnifeSlash = { Url = Animation.ability["knife-slash.rbxm"], Length = 0.8 },
	KnifeJab = { Url = Animation.ability["knife-jab.rbxm"], Length = 0.8 },
	Sheathing = { Url = Animation.ability["sheathing.rbxm"], Length = 0.8 },
	RightSlash = { Url = Animation.ability["right-slash.rbxm"], Length = 0.8 },
	LeftSlash = { Url = Animation.ability["left-slash.rbxm"], Length = 0.8 },
	ClawSheathing = { Url = Animation.ability["claw-sheathing.rbxm"], Length = 0.8 },
	PowerPunch = { Url = Animation.ability["power-punch.rbxm"], Length = 0.8 },
	Strike = { Url = Animation.ability["strike.rbxm"], Length = 0.8 },
	RightFootKick = { Url = Animation.ability["right-foot-kick.rbxm"], Length = 0.8 },
	ForcePush = { Url = Animation.ability["force-push.rbxm"], Length = 1 },
	ForceExplosion = { Url = Animation.ability["force-explosion.rbxm"], Length = 2 },
	IceSpin = { Url = Animation.ability["ice-spin.rbxm"], Length = 2 },
	PowerShot = { Url = Animation.ability["power-shot.rbxm"], Length = 2 },
	HeadShot = { Url = Animation.ability["head-shot.rbxm"], Length = 0.5 },
	GunShooting = { Url = Animation.ability["gun-shooting.rbxm"], Length = 2 },
	GunHolding = { Url = Animation.ability["gun-holding.rbxm"], Length = 4 },
	BowShooting = { Url = Animation.ability["bow-shooting.rbxm"], Length = 2 },
	BowHolding = { Url = Animation.ability["bow-holding.rbxm"], Length = 0.5 },
	WallClimbing = { Url = Animation.ability["wall-climbing.rbxm"], Length = 0.6 },
	FlightIdle = { Url = Animation.ability["flight-idle.rbxm"], Length = 4.5 },
	FlightMovement = { Url = Animation.ability["flight-movement.rbxm"], Length = 4.5 },
}
local MESHES: { [MeshKey]: MeshDefinition } = {
	Sword = { MeshUrl = "rbxasset://fonts/sword.mesh", TextureUrl = "" },
	ThrowingStar = { MeshUrl = "rbxassetid://11376946", TextureUrl = "" },
	Claw = { MeshUrl = "rbxassetid://10681506", TextureUrl = "" },
	Hammer = { MeshUrl = "rbxassetid://12592754", TextureUrl = Image.mesh["hammer.png"] },
	Katana = { MeshUrl = "rbxassetid://11442510", TextureUrl = "" },
	Knife = { MeshUrl = "rbxassetid://121944778", TextureUrl = "" },
	Trident = { MeshUrl = "rbxassetid://53926151", TextureUrl = "" },
	Rifle = { MeshUrl = "rbxassetid://72012671", TextureUrl = Image.mesh["rifle.png"] },
	Handgun = { MeshUrl = "rbxassetid://72012879", TextureUrl = Image.mesh["handgun.png"] },
	Bow = { MeshUrl = "rbxassetid://55709693", TextureUrl = "" },
	Arrow = { MeshUrl = "rbxassetid://1036682", TextureUrl = "" },
	Icicle = { MeshUrl = "rbxassetid://20518365", TextureUrl = Image.mesh["icicle.png"] },
}
local PARTICLES: { [ParticleKey]: ParticleDefinition } = {
	LightningLeft = {
		TextureUrl = Image.fx["lightning-left.png"],
		Rate = 30,
		Lifetime = NumberRange.new(0.1, 0.2),
		Size = 2,
		Rotation = NumberRange.new(-100, -1),
		Speed = 0,
		LightEmission = 1,
		IsLockedToPart = true,
	},
	LightningRight = {
		TextureUrl = Image.fx["lightning-right.png"],
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
local DECALS: { [DecalKey]: DecalDefinition } = {
	PsychicWave = { TextureUrl = Image.fx["shockwave.png"] },
	Shockwave = { TextureUrl = Image.fx["psychic-boom.png"] },
}
local CATALOGUE: VFXAssetCatalogue = {
	Sounds = SOUNDS,
	Animations = ANIMATIONS,
	Meshes = MESHES,
	Particles = PARTICLES,
	Decals = DECALS,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
