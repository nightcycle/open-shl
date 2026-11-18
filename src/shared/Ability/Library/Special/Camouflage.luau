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
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
-- what the client found under its pointer, as far as the avatar can take it on
export type Surface = ClientVFXType.Coat
export type Bindings = {
	Cast: EventBinding,
	Blend: ClientSignal<Surface>, -- word of what the click pointed at
	Miss: EventBinding, -- no word of it came, the click pointed at nothing
	Disguise: StateBinding, -- the avatar looks like what was pointed at
	Shed: EventBinding, -- a click the character can't pay for
	Fade: EventBinding, -- the look was on for as long as it lasts
}
-- Constants
local ID = "special_camouflage"
-- seconds the look of a surface stays on the avatar
local DURATION = 20
-- seconds word of what a click pointed at is waited for
local BLEND_TIMEOUT = 1
-- Variables
-- References
-- Private Functions
-- Class
local click = AbilityTrigger.during(
	AbilityTrigger.started(AbilityCondition.PRIMARY),
	AbilityTrigger.active(AbilityCondition.equipped(ID))
)
-- a click with the tool out gives the avatar the look of whatever the player points at, another one swaps it for
-- the look of what they point at then. the tool can be put away, the look stays until its time is up. a cast leaves
-- the look it found on by way of a state without one, so whatever shows it starts over with the new one. with a
-- look on, the same click is a cast or the end of one depending on the energy it finds, so the client has the say
-- on both: were each side to make up its own mind, the server could pay for a cast its client never made
local bindings: Bindings = {
	Cast = VFXBinding.event({ "Plain", "Blended" }, click, { To = "Casting", Authority = "Client" }),
	Blend = VFXBinding.signal({ "Casting" }, "Client", ClientVFXType.Coat, { To = "Blended" }) :: ClientSignal<Surface>,
	Miss = VFXBinding.event({ "Casting" }, AbilityTrigger.after(BLEND_TIMEOUT), { To = "Plain" }),
	Disguise = VFXBinding.state({ "Blended" }, AbilityTrigger.always()),
	Shed = VFXBinding.event({ "Blended" }, click, { To = "Plain", Authority = "Client" }),
	Fade = VFXBinding.event({ "Blended" }, AbilityTrigger.after(DURATION), { To = "Plain" }),
}

return table.freeze({
	Layout = VFXBinding.layout(ID, "Plain", true, bindings),
	-- what the machine of each half keeps the look the avatar has on under
	SurfaceKey = "Surface",
	-- what the avatar is heard changing + changing back with, on both sides
	CastSound = "Morph" :: VFXAssetDefinition.SoundKey,
	ResetSound = "MorphReset" :: VFXAssetDefinition.SoundKey,
})
