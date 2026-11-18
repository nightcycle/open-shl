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
	Start: EventBinding,
	Sprint: StateBinding, -- the avatar runs at full pace
	Skim: StateBinding, -- water carries whoever keeps moving, out of breath or not
	Exhaust: ServerSignal<nil>, -- the energy ran out, which only the server knows
	Rest: StateBinding, -- out of breath with the tool still out
	Recover: ServerSignal<nil>, -- there's energy to run on again
	Stop: EventBinding,
}
-- what both halves of the super speed have to agree on
export type Config = {
	Sound: VFXAssetDefinition.SoundKey, -- the wind around whoever runs
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_super-speed"
-- Variables
-- References
-- Private Functions
-- Class
local equipped = AbilityCondition.equipped(ID)
local exhaust: ServerSignal<nil> = VFXBinding.signal({ "Running" }, "Server", Type.none, { To = "Resting" })
local recover: ServerSignal<nil> = VFXBinding.signal({ "Resting" }, "Server", Type.none, { To = "Running" })
-- the avatar runs for as long as the tool is out + there's energy to run on. out of it the avatar walks until some
-- has come back, the tool doesn't have to be taken out again
local bindings: Bindings = {
	Start = VFXBinding.event({ "Walking" }, AbilityTrigger.started(equipped), { To = "Running" }),
	Sprint = VFXBinding.state({ "Running" }, AbilityTrigger.always()),
	Skim = VFXBinding.state({ "Running", "Resting" }, AbilityTrigger.always()),
	Exhaust = exhaust,
	Rest = VFXBinding.state({ "Resting" }, AbilityTrigger.always()),
	Recover = recover,
	Stop = VFXBinding.event({ "Running", "Resting" }, AbilityTrigger.stopped(equipped), { To = "Walking" }),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Walking", true, bindings),
	Config = table.freeze({
		Sound = "Wind" :: VFXAssetDefinition.SoundKey,
	}),
})

return ability
