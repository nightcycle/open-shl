--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ServerSignal<T> = AbilityType.ServerSignal<T>
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	TakeOff: EventBinding,
	Aloft: StateBinding, -- up in the air, pulled or not
	Idle: StateBinding, -- nothing pulls, the avatar stays where it was last headed
	Thrust: StateBinding, -- pulled to where the player points
	Exhaust: ServerSignal<nil>, -- the energy ran out, which only the server knows
	Land: EventBinding,
}
-- what both halves of the flight have to agree on
export type Config = {
	Sound: VFXAssetDefinition.SoundKey, -- the wind around whoever is up
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_flight"
-- seconds the avatar gets to ease into + out of how it holds itself in the air
local EASE_DURATION = 0.1
-- Variables
-- References
-- Private Functions
-- Class
local equipped = AbilityCondition.equipped(ID)
-- the tool stays in the hand, it has to be put away + taken out for another go
local exhaust: ServerSignal<nil> = VFXBinding.signal(
	{ "Flying" },
	"Server",
	Type.none,
	{ To = "Grounded", Duration = EASE_DURATION }
)
-- the avatar is up for as long as the tool is out + there's energy to stay there, holding the primary input pulls
-- it along
local bindings: Bindings = {
	TakeOff = VFXBinding.event(
		{ "Grounded" },
		AbilityTrigger.started(equipped),
		{ To = "Flying", Duration = EASE_DURATION }
	),
	Aloft = VFXBinding.state({ "Flying" }, AbilityTrigger.always()),
	Idle = VFXBinding.state({ "Flying" }, AbilityTrigger.inactive(AbilityCondition.PRIMARY)),
	Thrust = VFXBinding.state({ "Flying" }, AbilityTrigger.active(AbilityCondition.PRIMARY)),
	Exhaust = exhaust,
	Land = VFXBinding.event(
		{ "Flying" },
		AbilityTrigger.stopped(equipped),
		{ To = "Grounded", Duration = EASE_DURATION }
	),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Grounded", true, bindings),
	Config = table.freeze({
		Sound = "Wind" :: VFXAssetDefinition.SoundKey,
	}),
})

return ability
