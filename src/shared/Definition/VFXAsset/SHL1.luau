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
-- every one of them is as loud + as fast as its tool had it. a blade is heard by the two files the engine ships,
-- which is where its tools played them from
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	-- the string of the bow as it's let go of
	Bow = { Url = Audio["shl-1"].ability["bow.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- a kunai as it's readied + as the hand lets go of them: the two files of a blade, sped up
	Clink = { Url = "rbxasset://sounds/unsheath.wav", Volume = 0.5, PlaybackSpeed = 3 },
	Fling = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.6, PlaybackSpeed = 1.5 },
	-- a shot of the machine gun
	GunShot = { Url = Audio["shl-1"].ability["machine-gun.ogg"], Volume = 0.12, PlaybackSpeed = 1 },
	HammerDraw = { Url = Audio["shl-1"].ability["hammer-draw.ogg"], Volume = 1, PlaybackSpeed = 1 },
	HammerSwing = { Url = Audio["shl-1"].ability["hammer-swing.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the ice going up where its ball landed
	IceForm = { Url = Audio["shl-1"].ability["ice-form.ogg"], Volume = 0.5, PlaybackSpeed = 0.6 },
	-- an arrow, wherever it lands. the one file the bow of shl3 is heard by
	Impact = { Url = Audio.core.ability["arrow-thud.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the eyes, for as long as they burn
	LaserHum = { Url = Audio["shl-1"].ability["laser-hum.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
	-- the rope of the hook as it pulls
	Latch = { Url = Audio["shl-1"].ability["latch.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- its own laser, the healing one is heard by it too
	PewPew = { Url = Audio["shl-1"].ability["laser-blast.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the wall of the energy field going up
	Platforming = { Url = Audio["shl-1"].ability["energy-field.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the files shl2 has of these two are byte for byte the uploads this game made
	PortalShot = { Url = Audio.core.ability["portal-shot.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Shock = { Url = Audio.core.ability["shock.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Slash = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.7, PlaybackSpeed = 1 },
	-- a kunai or a wall of the field, where it comes to stand
	Thunk = { Url = Audio["shl-1"].ability["thunk.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- whoever comes out of a portal
	Transwarp = { Url = Audio["shl-1"].ability["portal-travel.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
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
	HeadShot = { Url = Animation.core.ability["head-shot.rbxm"], Length = 0.5 },
	GunShooting = { Url = Animation.core.ability["gun-shooting.rbxm"], Length = 2 },
	GunHolding = { Url = Animation.core.ability["gun-holding.rbxm"], Length = 4 },
	BowShooting = { Url = Animation.core.ability["bow-shooting.rbxm"], Length = 2 },
	BowHolding = { Url = Animation.core.ability["bow-holding.rbxm"], Length = 0.5 },
	FlightIdle = { Url = Animation.core.ability["flight-idle.rbxm"], Length = 4.5 },
	FlightMovement = { Url = Animation.core.ability["flight-movement.rbxm"], Length = 4.5 },
}
-- the bow is the one shl2 holds, what it shoots is the game's own arrow. the star, the hammer + the icicle are what
-- shl2 took over from this game, the rest are its own
local MESHES: { [MeshKey]: MeshDefinition } = {
	ThrowingStar = { MeshUrl = "rbxassetid://11376946", TextureUrl = "" },
	Hammer = { MeshUrl = "rbxassetid://12592754", TextureUrl = Image.core.mesh["hammer.png"] },
	Katana = { MeshUrl = "rbxassetid://11442510", TextureUrl = Image["shl-1"].mesh["katana.png"] },
	Bow = { MeshUrl = "rbxassetid://55709693", TextureUrl = "" },
	Arrow = { MeshUrl = "rbxassetid://15887356", TextureUrl = Image["shl-1"].mesh["bow-bolt.png"] },
	Icicle = { MeshUrl = "rbxassetid://20518365", TextureUrl = Image.core.mesh["icicle.png"] },
	Sai = { MeshUrl = "rbxassetid://51229672", TextureUrl = Image["shl-1"].mesh["sai.png"] },
	Kunai = { MeshUrl = "rbxassetid://45728702", TextureUrl = Image["shl-1"].mesh["kunai.png"] },
	MachineGun = { MeshUrl = "rbxassetid://98400644", TextureUrl = "" },
	Portal = { MeshUrl = "rbxassetid://3270017", TextureUrl = Image["shl-1"].mesh["portal-beam.png"] },
}
-- the sparks of the lightning are the pictures shl2 has, given off the way this game's own emitter was set
local PARTICLES: { [ParticleKey]: ParticleDefinition } = {
	LightningLeft = {
		TextureUrl = Image.core.fx["lightning-left.png"],
		Rate = 30,
		Lifetime = NumberRange.new(0.1, 0.2),
		Size = 1,
		Rotation = NumberRange.new(0),
		Speed = 0,
		LightEmission = 0,
		IsLockedToPart = false,
	},
	LightningRight = {
		TextureUrl = Image.core.fx["lightning-right.png"],
		Rate = 30,
		Lifetime = NumberRange.new(0.1, 0.2),
		Size = 1,
		Rotation = NumberRange.new(0),
		Speed = 0,
		LightEmission = 0,
		IsLockedToPart = false,
	},
}
-- the pointers a tool swaps the mouse's for. the machine gun's is red, purple while it reloads
local DECALS: { [DecalKey]: DecalDefinition } = {
	CursorBow = { TextureUrl = Image["shl-1"].ui.cursor["bow.png"] },
	CursorGun = { TextureUrl = Image["shl-1"].ui.cursor["machine-gun-red.png"] },
	CursorReload = { TextureUrl = Image["shl-1"].ui.cursor["machine-gun-purple.png"] },
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
