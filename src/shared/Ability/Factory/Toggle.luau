--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	Cast: EventBinding,
	Sustain: StateBinding, -- it's on
	Cancel: EventBinding, -- a second click
	PutAway: EventBinding, -- the tool leaves the hand
	Expire: EventBinding, -- it was on for as long as it lasts
	Finish: EventBinding, -- it's off again, whatever turned it off
}
-- what both halves of a toggled ability have to agree on
export type Config = {
	Duration: number, -- seconds it stays on at most
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the bindings of an ability that's turned on: a click with the tool out turns it on, it's off again with the next
-- click, as the tool is put away or once its time is up, whichever comes first. the same click turns it on or off
-- depending on what it finds, so the client has the say on both: were each side to make up its own mind, a click
-- only one of them counts would leave it on for one + off for the other
Module.new = function(id: string, config: Config): Ability
	local equipped = AbilityCondition.equipped(id)
	local click =
		AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped))
	local bindings: Bindings = {
		Cast = VFXBinding.event({ "Idle" }, click, { To = "Active", Authority = "Client" }),
		Sustain = VFXBinding.state({ "Active" }, AbilityTrigger.always()),
		Cancel = VFXBinding.event({ "Active" }, click, { To = "Idle", Authority = "Client" }),
		PutAway = VFXBinding.event({ "Active" }, AbilityTrigger.stopped(equipped), { To = "Idle" }),
		Expire = VFXBinding.event({ "Active" }, AbilityTrigger.after(config.Duration), { To = "Idle" }),
		Finish = VFXBinding.event({ "Active" }, AbilityTrigger.exited()),
	}
	return table.freeze({
		Layout = VFXBinding.layout(id, "Idle", true, bindings),
		Config = table.freeze(table.clone(config)),
	})
end

return Module
