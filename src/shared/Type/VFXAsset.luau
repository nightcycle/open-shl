--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

-- an effect names what it plays by key rather than by url, so nothing a client sends can make others load
-- something the game doesn't ship
export type SoundKey =
	"Boom"
	| "Bow"
	| "CanOpen"
	| "CheeseburgerBite"
	| "CheeseburgerOpen"
	| "Clink"
	| "Drink"
	| "Fling"
	| "ForceWhoosh"
	| "GunShot"
	| "HammerDraw"
	| "HammerSwing"
	| "IceCreamLick"
	| "IceForm"
	| "Impact"
	| "LaserHum"
	| "Latch"
	| "Moneybag1"
	| "Moneybag2"
	| "Moneybag3"
	| "Morph"
	| "MorphReset"
	| "PewPew"
	| "PizzaBite"
	| "PizzaOpen"
	| "Platforming"
	| "PortalShot"
	| "Sheath"
	| "Shock"
	| "Slash"
	| "Thunk"
	| "Transwarp"
	| "Unsheath"
	| "WatermelonBite"
	| "WindGust"
	| "Wind"
Types.SoundKey = Type.literal(
	"Boom",
	"Bow",
	"CanOpen",
	"CheeseburgerBite",
	"CheeseburgerOpen",
	"Clink",
	"Drink",
	"Fling",
	"ForceWhoosh",
	"GunShot",
	"HammerDraw",
	"HammerSwing",
	"IceCreamLick",
	"IceForm",
	"Impact",
	"LaserHum",
	"Latch",
	"Moneybag1",
	"Moneybag2",
	"Moneybag3",
	"Morph",
	"MorphReset",
	"PewPew",
	"PizzaBite",
	"PizzaOpen",
	"Platforming",
	"PortalShot",
	"Sheath",
	"Shock",
	"Slash",
	"Thunk",
	"Transwarp",
	"Unsheath",
	"WatermelonBite",
	"WindGust",
	"Wind"
)
export type SoundDefinition = {
	Url: string,
	Volume: number,
	PlaybackSpeed: number,
}
Types.SoundDefinition = Type.strictInterface({
	Url = Type.string,
	Volume = Type.numberMin(0),
	PlaybackSpeed = Type.numberPositive,
})
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
Types.AnimationKey = Type.literal(
	"KnifeSlash",
	"KnifeJab",
	"Sheathing",
	"RightSlash",
	"LeftSlash",
	"ClawSheathing",
	"PowerPunch",
	"Strike",
	"RightFootKick",
	"ForcePush",
	"ForceExplosion",
	"IceSpin",
	"PowerShot",
	"HeadShot",
	"GunShooting",
	"GunHolding",
	"BowShooting",
	"BowHolding",
	"WallClimbing",
	"FlightIdle",
	"FlightMovement"
)
export type AnimationDefinition = {
	Url: string,
	Length: number, -- seconds until whatever it's the wind-up of is over
}
Types.AnimationDefinition = Type.strictInterface({
	Url = Type.string,
	Length = Type.numberPositive,
})
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
	| "Cheeseburger"
	| "BoStaff"
	| "Minigun"
	| "Sai"
	| "Kunai"
	| "MachineGun"
	| "Portal"
	| "Pizza"
	| "Watermelon"
	| "BloxyCola"
	| "Latte"
	| "Bloxiade"
	| "IceCream"
	| "PizzaBox"
	| "Tablet"
	| "FidgetSpinner"
	| "Moneybag"
	| "AcousticGuitar"
	| "ElectricGuitar"
	| "FishingPole"
	| "Sinker"
	| "FishGreen"
	| "FishOrange"
	| "FishSilver"
Types.MeshKey = Type.literal(
	"Sword",
	"ThrowingStar",
	"Claw",
	"Hammer",
	"Katana",
	"Knife",
	"Trident",
	"Rifle",
	"Handgun",
	"Bow",
	"Arrow",
	"Icicle",
	"Cheeseburger",
	"BoStaff",
	"Minigun",
	"Sai",
	"Kunai",
	"MachineGun",
	"Portal",
	"Pizza",
	"Watermelon",
	"BloxyCola",
	"Latte",
	"Bloxiade",
	"IceCream",
	"PizzaBox",
	"Tablet",
	"FidgetSpinner",
	"Moneybag",
	"AcousticGuitar",
	"ElectricGuitar",
	"FishingPole",
	"Sinker",
	"FishGreen",
	"FishOrange",
	"FishSilver"
)
export type MeshDefinition = {
	MeshUrl: string,
	TextureUrl: string,
}
Types.MeshDefinition = Type.strictInterface({
	MeshUrl = Type.string,
	TextureUrl = Type.string,
})
export type ParticleKey = "LightningLeft" | "LightningRight" | "Tornado" | "Flash" | "Snow" | "Ember"
Types.ParticleKey = Type.literal("LightningLeft", "LightningRight", "Tornado", "Flash", "Snow", "Ember")
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
	LightInfluence: number?, -- how much of the light around them they take on, all of it without
	RotationSpeed: number?, -- degrees a second they turn at, they don't without
	SpreadAngle: number?, -- degrees they're given off at either side of straight up, none without
	Transparency: NumberSequence?, -- over their life, they're there until they're gone without
	VelocityInheritance: number?, -- how much of the pace of what gives them off they set out with, none without
}
Types.ParticleDefinition = Type.strictInterface({
	TextureUrl = Type.string,
	Rate = Type.numberMin(0),
	Lifetime = Type.NumberRange,
	Size = Type.numberMin(0),
	Rotation = Type.NumberRange,
	Speed = Type.number,
	LightEmission = Type.numberConstrained(0, 1),
	IsLockedToPart = Type.boolean,
	Color = Type.optional(Type.ColorSequence),
	EndSize = Type.optional(Type.numberMin(0)),
	LightInfluence = Type.optional(Type.numberConstrained(0, 1)),
	RotationSpeed = Type.optional(Type.number),
	SpreadAngle = Type.optional(Type.number),
	Transparency = Type.optional(Type.NumberSequence),
	VelocityInheritance = Type.optional(Type.number),
})
export type DecalKey = "PsychicWave" | "Shockwave" | "CursorBow" | "CursorGun" | "CursorReload" | "Bill"
Types.DecalKey = Type.literal("PsychicWave", "Shockwave", "CursorBow", "CursorGun", "CursorReload", "Bill")
export type DecalDefinition = {
	TextureUrl: string,
}
Types.DecalDefinition = Type.strictInterface({
	TextureUrl = Type.string,
})

-- what the effects of one game get to play + show. the keys are every game's, the rows a game's own: it only has one
-- for what its abilities name
export type VFXAssetCatalogue = {
	Sounds: { [SoundKey]: SoundDefinition },
	Animations: { [AnimationKey]: AnimationDefinition },
	Meshes: { [MeshKey]: MeshDefinition },
	Particles: { [ParticleKey]: ParticleDefinition },
	Decals: { [DecalKey]: DecalDefinition },
}
Types.VFXAssetCatalogue = Type.strictInterface({
	Sounds = Type.map(Types.SoundKey, Types.SoundDefinition),
	Animations = Type.map(Types.AnimationKey, Types.AnimationDefinition),
	Meshes = Type.map(Types.MeshKey, Types.MeshDefinition),
	Particles = Type.map(Types.ParticleKey, Types.ParticleDefinition),
	Decals = Type.map(Types.DecalKey, Types.DecalDefinition),
})

return Types
