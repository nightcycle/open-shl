--!strict
-- Services
-- Packages
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
local Audio = require("@game/ReplicatedStorage/Generated/Audio")
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
-- every one of them is heard the way it was uploaded: nothing is turned down or slowed
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	-- the one file an arrow of shl1 is heard landing by
	Bow = { Url = Audio.core.ability["arrow-thud.ogg"], Volume = 1, PlaybackSpeed = 1 },
	GunShot = { Url = Audio["shl-3"].ability["gun-shot.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the one file both games shoot their lasers with
	PewPew = { Url = Audio.core.ability["pew-pew.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Slash = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.7, PlaybackSpeed = 1 },
}
-- its own takes on the moves of the same name, each as long as its last keyframe is in
local ANIMATIONS: { [AnimationKey]: AnimationDefinition } = {
	Sheathing = { Url = Animation["shl-3"].ability["sheathing.rbxm"], Length = 0.5 },
	RightSlash = { Url = Animation["shl-3"].ability["right-slash.rbxm"], Length = 0.8 },
	LeftSlash = { Url = Animation["shl-3"].ability["left-slash.rbxm"], Length = 0.8 },
	PowerPunch = { Url = Animation["shl-3"].ability["power-punch.rbxm"], Length = 0.8 },
	Strike = { Url = Animation["shl-3"].ability["strike.rbxm"], Length = 0.8 },
	RightFootKick = { Url = Animation["shl-3"].ability["right-foot-kick.rbxm"], Length = 0.8 },
	GunShooting = { Url = Animation["shl-3"].ability["gun-shooting.rbxm"], Length = 0.25 },
	-- its own upload of it is keyframe for keyframe the one that's shipped already
	GunHolding = { Url = Animation.core.ability["gun-holding.rbxm"], Length = 4 },
	FlightIdle = { Url = Animation["shl-3"].ability["flight-idle.rbxm"], Length = 4.5 },
	FlightMovement = { Url = Animation["shl-3"].ability["flight-movement.rbxm"], Length = 4.5 },
}
local MESHES: { [MeshKey]: MeshDefinition } = {
	Claw = { MeshUrl = "rbxassetid://10681506", TextureUrl = "" },
	Katana = { MeshUrl = "rbxassetid://11442510", TextureUrl = "" },
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
