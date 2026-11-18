--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local VFXAssetType = require("@game/ReplicatedStorage/Shared/Type/VFXAsset")
export type SoundKey = VFXAssetType.SoundKey
export type SoundDefinition = VFXAssetType.SoundDefinition
export type AnimationKey = VFXAssetType.AnimationKey
export type AnimationDefinition = VFXAssetType.AnimationDefinition
export type MeshKey = VFXAssetType.MeshKey
export type MeshDefinition = VFXAssetType.MeshDefinition
export type ParticleKey = VFXAssetType.ParticleKey
export type ParticleDefinition = VFXAssetType.ParticleDefinition
export type DecalKey = VFXAssetType.DecalKey
export type DecalDefinition = VFXAssetType.DecalDefinition
type VFXAssetCatalogue = VFXAssetType.VFXAssetCatalogue
-- Constants
-- what a key plays or shows is the game's own, the sounds + animations of another game are never required
local CATALOGUE: VFXAssetCatalogue = GameDefinition.pick({
	shl1 = function(): VFXAssetCatalogue
		error(`shl1 has no effect assets yet`)
	end,
	shl2 = function(): VFXAssetCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): VFXAssetCatalogue
		return require("@self/SHL3")
	end,
})
assert(VFXAssetType.VFXAssetCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local SOUNDS = CATALOGUE.Sounds
local ANIMATIONS = CATALOGUE.Animations
local MESHES = CATALOGUE.Meshes
local PARTICLES = CATALOGUE.Particles
local DECALS = CATALOGUE.Decals
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

-- only what the game that's built has a row for gets through, so an effect is turned down before it's shown
Module.SoundKey = isKey(SOUNDS)
Module.AnimationKey = isKey(ANIMATIONS)
Module.MeshKey = isKey(MESHES)
Module.ParticleKey = isKey(PARTICLES)
Module.DecalKey = isKey(DECALS)

-- a key every game knows + this one has no row for is somebody's slip, not something to play nothing for
Module.getSound = function(key: SoundKey): SoundDefinition
	local definition = SOUNDS[key]
	assert(definition, `the game has no sound "{key}"`)
	return definition
end

Module.getAnimation = function(key: AnimationKey): AnimationDefinition
	local definition = ANIMATIONS[key]
	assert(definition, `the game has no animation "{key}"`)
	return definition
end

Module.getMesh = function(key: MeshKey): MeshDefinition
	local definition = MESHES[key]
	assert(definition, `the game has no mesh "{key}"`)
	return definition
end

Module.getParticle = function(key: ParticleKey): ParticleDefinition
	local definition = PARTICLES[key]
	assert(definition, `the game has no particle "{key}"`)
	return definition
end

Module.getDecal = function(key: DecalKey): DecalDefinition
	local definition = DECALS[key]
	assert(definition, `the game has no decal "{key}"`)
	return definition
end

return Module
