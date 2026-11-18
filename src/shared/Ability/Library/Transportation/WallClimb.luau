--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type ServerSignal<T> = AbilityType.ServerSignal<T>
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	Seek: StateBinding, -- the tool is out + the avatar isn't on a wall, its client feels for one
	Cling: ClientSignal<nil>, -- the avatar is up against a wall
	Climb: StateBinding, -- the avatar rises along the wall
	Release: ClientSignal<nil>, -- the wall is behind the avatar: over its top or walked away from
	Exhaust: ServerSignal<nil>, -- the energy ran out, which only the server knows
	Sheathe: EventBinding,
}
-- what both halves of the wall climb have to agree on
export type Config = {
	ProbeRange: number, -- studs ahead of the avatar a wall is felt for
	ClingDistance: number, -- studs ahead of the middle of the avatar a wall has to be within to be climbed
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_wall-climb"
-- Variables
-- References
-- Private Functions
-- Class
local equipped = AbilityCondition.equipped(ID)
local cling: ClientSignal<nil> = VFXBinding.signal({ "Idle" }, "Client", Type.none, { To = "Climbing" })
local release: ClientSignal<nil> = VFXBinding.signal({ "Climbing" }, "Client", Type.none, { To = "Idle" })
local exhaust: ServerSignal<nil> = VFXBinding.signal({ "Climbing" }, "Server", Type.none, { To = "Idle" })
-- with the tool out, an avatar that's walked up against a wall rises along it for as long as there's energy to. the
-- avatar is its client's to move, so it's the client that says when it's on a wall + when it's off again
local bindings: Bindings = {
	Seek = VFXBinding.state({ "Idle" }, AbilityTrigger.active(equipped)),
	Cling = cling,
	Climb = VFXBinding.state({ "Climbing" }, AbilityTrigger.always()),
	Release = release,
	Exhaust = exhaust,
	Sheathe = VFXBinding.event({ "Climbing" }, AbilityTrigger.stopped(equipped), { To = "Idle" }),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = table.freeze({
		ProbeRange = 50,
		ClingDistance = 1,
	}),
})

return ability
