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
-- every one of them is as loud as its tool had it + none is slowed. a blade is heard by the two files the engine
-- ships, which is where its tools played them from
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	-- the string of the bow as it's let go of
	Bow = { Url = Audio["shl-1"].ability["bow.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- an arrow, wherever it lands. the one file the bow of shl3 is heard by
	Impact = { Url = Audio.core.ability["arrow-thud.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Slash = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.7, PlaybackSpeed = 1 },
	Unsheath = { Url = "rbxasset://sounds/unsheath.wav", Volume = 1, PlaybackSpeed = 1 },
}
-- the game never had a move for a body that bends, these are the ones shl2 swings, shoots + flies by
local ANIMATIONS: { [AnimationKey]: AnimationDefinition } = {
	RightSlash = { Url = Animation.core.ability["right-slash.rbxm"], Length = 0.8 },
	LeftSlash = { Url = Animation.core.ability["left-slash.rbxm"], Length = 0.8 },
	PowerPunch = { Url = Animation.core.ability["power-punch.rbxm"], Length = 0.8 },
	Strike = { Url = Animation.core.ability["strike.rbxm"], Length = 0.8 },
	RightFootKick = { Url = Animation.core.ability["right-foot-kick.rbxm"], Length = 0.8 },
	PowerShot = { Url = Animation.core.ability["power-shot.rbxm"], Length = 2 },
	BowShooting = { Url = Animation.core.ability["bow-shooting.rbxm"], Length = 2 },
	BowHolding = { Url = Animation.core.ability["bow-holding.rbxm"], Length = 0.5 },
	FlightIdle = { Url = Animation.core.ability["flight-idle.rbxm"], Length = 4.5 },
	FlightMovement = { Url = Animation.core.ability["flight-movement.rbxm"], Length = 4.5 },
}
-- the bow is the one shl2 holds, what it shoots is the game's own arrow
local MESHES: { [MeshKey]: MeshDefinition } = {
	Bow = { MeshUrl = "rbxassetid://55709693", TextureUrl = "" },
	Arrow = { MeshUrl = "rbxassetid://15887356", TextureUrl = Image["shl-1"].mesh["bow-bolt.png"] },
}
local PARTICLES: { [ParticleKey]: ParticleDefinition } = {}
local DECALS: { [DecalKey]: DecalDefinition } = {}
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
