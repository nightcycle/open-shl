--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type Layout<B> = AbilityType.Layout<B>
type SoundKey = VFXAssetDefinition.SoundKey
export type Bindings = {
	Cast: EventBinding, -- the field is thrown, the way the click that cast it pointed
	Recover: EventBinding,
}
-- what both halves of the field have to agree on
export type Config = {
	Cooldown: number, -- seconds from a click until the next one counts
	Size: Vector3, -- of the field, as it's thrown + as it stands
	Start: number, -- studs off the middle of the avatar it sets out from
	Speed: number, -- studs a second it flies at
	Lifetime: number, -- seconds from the click until it's gone, wherever it got to
	Transparency: number, -- how far it's seen through as it's thrown
	EndTransparency: number, -- how far it's seen through by the time it goes
	Color: Color3, -- what it's drawn in for a character that has no color for it
	CastSound: SoundKey,
	LandSound: SoundKey, -- heard as it sticks
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "special_energy-field"
local CONFIG: Config = {
	Cooldown = 1,
	Size = Vector3.new(7, 7, 0.2),
	Start = 10,
	Speed = 50,
	Lifetime = 9,
	Transparency = 0.6,
	EndTransparency = 0.9,
	Color = Color3.fromRGB(248, 248, 248),
	CastSound = "Platforming",
	LandSound = "Thunk",
}
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out throws a field of light the way the player points. it sticks to the first thing of the
-- world it runs into + stands there as a wall for what's left of its time. the tool can be put away right after: the
-- field still flies + the next one still has to wait
local bindings: Bindings = {
	Cast = VFXBinding.event(
		{ "Idle" },
		AbilityTrigger.during(
			AbilityTrigger.started(AbilityCondition.PRIMARY),
			AbilityTrigger.active(AbilityCondition.equipped(ID))
		),
		{ To = "Casting" }
	),
	Recover = VFXBinding.event({ "Casting" }, AbilityTrigger.after(CONFIG.Cooldown), { To = "Idle" }),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = table.freeze(CONFIG),
})

return ability
