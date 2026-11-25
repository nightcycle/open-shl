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
-- every one of them is as loud as whatever played it had it: a power's as it was uploaded, a drink + the ice cream
-- at half of that. none is slowed
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	-- the one file an arrow of shl1 is heard landing by
	Bow = { Url = Audio.core.ability["arrow-thud.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the can of a cola as it's taken out
	CanOpen = { Url = Audio["shl-3"].prop["can-open.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
	-- a bite of the burger + the wrapper coming off it
	CheeseburgerBite = { Url = Audio["shl-3"].prop["cheeseburger-bite.ogg"], Volume = 1, PlaybackSpeed = 1 },
	CheeseburgerOpen = { Url = Audio["shl-3"].prop["cheeseburger-open.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- a sip of the cola, the latte or the bloxiade
	Drink = { Url = Audio["shl-3"].prop["drink.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
	GunShot = { Url = Audio["shl-3"].ability["gun-shot.ogg"], Volume = 1, PlaybackSpeed = 1 },
	IceCreamLick = { Url = Audio["shl-3"].prop["ice-cream-lick.ogg"], Volume = 0.5, PlaybackSpeed = 1 },
	-- the three the moneybag is heard by
	Moneybag1 = { Url = Audio["shl-3"].prop["moneybag-1.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Moneybag2 = { Url = Audio["shl-3"].prop["moneybag-2.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Moneybag3 = { Url = Audio["shl-3"].prop["moneybag-3.ogg"], Volume = 1, PlaybackSpeed = 1 },
	-- the one file both games shoot their lasers with
	PewPew = { Url = Audio.core.ability["pew-pew.ogg"], Volume = 1, PlaybackSpeed = 1 },
	PizzaBite = { Url = Audio["shl-3"].prop["pizza-bite.ogg"], Volume = 1, PlaybackSpeed = 1 },
	PizzaOpen = { Url = Audio["shl-3"].prop["pizza-open.ogg"], Volume = 1, PlaybackSpeed = 1 },
	Slash = { Url = "rbxasset://sounds/swordslash.wav", Volume = 0.7, PlaybackSpeed = 1 },
	WatermelonBite = { Url = Audio["shl-3"].prop["watermelon-bite.ogg"], Volume = 1, PlaybackSpeed = 1 },
}
-- its own takes on the moves of the same name, each as long as its last keyframe is in
local ANIMATIONS: { [AnimationKey]: AnimationDefinition } = {
	KnifeSlash = { Url = Animation["shl-3"].ability["knife-slash.rbxm"], Length = 0.8 },
	KnifeJab = { Url = Animation["shl-3"].ability["knife-jab.rbxm"], Length = 0.8 },
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
-- the hammer, the bow + the arrow are its own, not the ones shl2 has under the same names
local MESHES: { [MeshKey]: MeshDefinition } = {
	Sword = { MeshUrl = "rbxasset://fonts/sword.mesh", TextureUrl = "rbxasset://textures/SwordTexture.png" },
	Claw = { MeshUrl = "rbxassetid://10681506", TextureUrl = "" },
	Hammer = { MeshUrl = "rbxassetid://1279013", TextureUrl = Image["shl-3"].mesh["hammer.png"] },
	Katana = { MeshUrl = "rbxassetid://11442510", TextureUrl = "" },
	Bow = { MeshUrl = "rbxassetid://121945106", TextureUrl = "" },
	Arrow = { MeshUrl = "rbxassetid://95920149", TextureUrl = Image["shl-3"].mesh["arrow.png"] },
	BoStaff = { MeshUrl = "rbxassetid://46668969", TextureUrl = "" },
	Minigun = { MeshUrl = "rbxassetid://552654489", TextureUrl = "" },
	-- what a prop is drawn by comes with the picture it was uploaded with
	Cheeseburger = { MeshUrl = "rbxassetid://16646125", TextureUrl = "rbxassetid://16432575" },
	Pizza = { MeshUrl = "rbxassetid://22589477", TextureUrl = "rbxassetid://22589467" },
	Watermelon = { MeshUrl = "rbxassetid://22770654", TextureUrl = "rbxassetid://22770653" },
	BloxyCola = { MeshUrl = "rbxassetid://10470609", TextureUrl = "rbxassetid://10470600" },
	Latte = { MeshUrl = "rbxassetid://15929962", TextureUrl = "rbxassetid://15929949" },
	Bloxiade = { MeshUrl = "rbxassetid://17230208", TextureUrl = "rbxassetid://17230185" },
	IceCream = { MeshUrl = "rbxassetid://57718450", TextureUrl = "rbxassetid://57718359" },
	PizzaBox = { MeshUrl = "rbxassetid://125736357", TextureUrl = "rbxassetid://125728597" },
	Tablet = { MeshUrl = "rbxassetid://97689497", TextureUrl = "rbxassetid://97689055" },
	FidgetSpinner = { MeshUrl = "rbxassetid://915251142", TextureUrl = "rbxassetid://915250609" },
	Moneybag = { MeshUrl = "rbxassetid://16657069", TextureUrl = "rbxassetid://16657057" },
	AcousticGuitar = { MeshUrl = "rbxassetid://26639749", TextureUrl = "rbxassetid://26639722" },
	ElectricGuitar = { MeshUrl = "rbxassetid://1082816", TextureUrl = "rbxassetid://10504421" },
	FishingPole = { MeshUrl = "rbxassetid://446888188", TextureUrl = "" },
	-- the weight at the end of the pole's line, the hook of the grapple is the same mesh
	Sinker = { MeshUrl = "rbxassetid://30307623", TextureUrl = "rbxassetid://30307531" },
	-- one fish, in the three pictures it's caught in
	FishGreen = { MeshUrl = "rbxassetid://56844224", TextureUrl = "rbxassetid://272625413" },
	FishOrange = { MeshUrl = "rbxassetid://56844224", TextureUrl = "rbxassetid://275958498" },
	FishSilver = { MeshUrl = "rbxassetid://56844224", TextureUrl = "rbxassetid://273864126" },
}
-- what its powers give off, as the game had each emitter set: the flash at the muzzle of the minigun, the snow + the
-- embers off the hand of the two rays. a row has one size at either end, one speed + one turn
local PARTICLES: { [ParticleKey]: ParticleDefinition } = {
	Flash = {
		TextureUrl = Image["shl-3"].fx["flash.png"],
		Rate = 20,
		Lifetime = NumberRange.new(0, 0.4),
		Size = 0.25,
		Rotation = NumberRange.new(0),
		Speed = 1.5,
		LightEmission = 1,
		IsLockedToPart = true,
		Color = ColorSequence.new(Color3.new(1, 1, 0)),
		EndSize = 0,
		LightInfluence = 0,
		RotationSpeed = 200,
		SpreadAngle = 180,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.89, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	},
	Snow = {
		TextureUrl = Image["shl-3"].fx["snow.png"],
		Rate = 30,
		Lifetime = NumberRange.new(1, 2),
		Size = 0.8125,
		Rotation = NumberRange.new(0),
		Speed = 1.5,
		LightEmission = 0.2,
		IsLockedToPart = true,
		EndSize = 0,
		LightInfluence = 0.5,
		SpreadAngle = 180,
		Transparency = NumberSequence.new(0, 1),
	},
	Ember = {
		TextureUrl = Image["shl-3"].fx["fire.png"],
		Rate = 65,
		Lifetime = NumberRange.new(0.5, 1),
		Size = 0.3125,
		Rotation = NumberRange.new(0),
		Speed = 1,
		LightEmission = 0.5,
		IsLockedToPart = false,
		Color = ColorSequence.new(Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 0, 0)),
		EndSize = 0,
		LightInfluence = 0,
		RotationSpeed = 500,
	},
}
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
