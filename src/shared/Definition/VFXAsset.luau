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
export type MeshKey = "Sword"
export type MeshDefinition = {
	MeshUrl: string,
	TextureUrl: string,
}
-- Constants
local SOUNDS: { [SoundKey]: SoundDefinition } = {
	Boom = { Url = "rbxasset://sounds/Rocket shot.wav", Volume = 0.7, PlaybackSpeed = 1 },
	Bow = { Url = "rbxassetid://173979241", Volume = 0.5, PlaybackSpeed = 1 },
	ForceWhoosh = { Url = "rbxassetid://580313487", Volume = 1, PlaybackSpeed = 1 },
	GunShot = { Url = "rbxassetid://356911785", Volume = 0.25, PlaybackSpeed = 1 },
	Impact = { Url = "rbxassetid://177172187", Volume = 1, PlaybackSpeed = 1 },
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
}
TableUtil.deepFreeze(MESHES)
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

Module.getSound = function(key: SoundKey): SoundDefinition
	return SOUNDS[key]
end

Module.getAnimation = function(key: AnimationKey): AnimationDefinition
	return ANIMATIONS[key]
end

Module.getMesh = function(key: MeshKey): MeshDefinition
	return MESHES[key]
end

return Module
