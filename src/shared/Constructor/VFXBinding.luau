--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Validator = VFXType.Validator
type EventTrigger = AbilityType.EventTrigger
type StateTrigger = AbilityType.StateTrigger
type Authority = AbilityType.Authority
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type Binding = AbilityType.Binding
type Layout<B> = AbilityType.Layout<B>
export type EventOptions = {
	To: string?, -- the state the machine is in afterwards
	Duration: number?, -- seconds the effects of the two states get to ease into each other
	Authority: Authority?, -- both sides work it out for themselves unless one is named
}
export type SignalOptions = {
	To: string?,
	Duration: number?,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- fires as its trigger does while the machine is in one of the states
Module.event = function(stateIds: { string }, trigger: EventTrigger, options: EventOptions?): EventBinding
	return table.freeze({
		Kind = "Event" :: "Event",
		Name = "",
		StateIds = table.freeze(table.clone(stateIds)),
		Trigger = trigger,
		Authority = (options and options.Authority or "Both") :: Authority,
		Payload = Type.none,
		To = options and options.To,
		Duration = options and options.Duration,
	})
end

-- fires when the half that has the say raises it, with a payload the other half checks as it's told. the type of
-- the payload is cast on by whoever defines the binding: `:: ClientSignal<Hit>`
Module.signal = function(
	stateIds: { string },
	authority: "Client" | "Server",
	payload: Validator,
	options: SignalOptions?
): any
	return table.freeze({
		Kind = "Event" :: "Event",
		Name = "",
		StateIds = table.freeze(table.clone(stateIds)),
		Authority = authority,
		Payload = payload,
		To = options and options.To,
		Duration = options and options.Duration,
	})
end

-- on for as long as its trigger is while the machine is in one of the states. it runs on undisturbed as the
-- machine moves between two of them
Module.state = function(stateIds: { string }, trigger: StateTrigger): StateBinding
	return table.freeze({
		Kind = "State" :: "State",
		Name = "",
		StateIds = table.freeze(table.clone(stateIds)),
		Trigger = trigger,
	})
end

-- the bindings of one ability, each named by the key it's listed under
Module.layout = function<B>(id: string, initialStateId: string, hasTool: boolean, bindings: B): Layout<B>
	local stateIds: { [string]: true } = { [initialStateId] = true }
	local named: { [string]: Binding } = {}
	for name, binding: any in bindings :: any do
		local copy = table.clone(binding)
		copy.Name = name
		named[name] = table.freeze(copy)
		for _, stateId in binding.StateIds do
			stateIds[stateId] = true
		end
	end
	for name, binding in named do
		assert(#binding.StateIds > 0, `"{name}" of "{id}" isn't in any state`)
		if binding.Kind == "Event" and binding.To then
			assert(stateIds[binding.To], `"{name}" of "{id}" leads to "{binding.To}", no binding is in that state`)
		end
	end
	return table.freeze({
		Id = id,
		InitialStateId = initialStateId,
		HasTool = hasTool,
		Bindings = table.freeze(named) :: any,
	})
end

return Module
