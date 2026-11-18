--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type Condition = AbilityType.Condition
type Requirement = AbilityType.Requirement
type EventTrigger = AbilityType.EventTrigger
type StateTrigger = AbilityType.StateTrigger
-- Constants
-- Variables
-- References
-- Private Functions
local function newEvent(condition: Condition, isStarted: boolean, requirements: { Requirement }): EventTrigger
	return table.freeze({
		Kind = "Event" :: "Event",
		Condition = condition,
		IsStarted = isStarted,
		Requirements = table.freeze(requirements),
	})
end

local function newState(requirements: { Requirement }): StateTrigger
	return table.freeze({
		Kind = "State" :: "State",
		Requirements = table.freeze(requirements),
	})
end
-- Class
local Module = {}

-- an event: the instant the condition turns true
Module.started = function(condition: Condition): EventTrigger
	return newEvent(condition, true, {})
end

-- an event: the instant the condition turns false
Module.stopped = function(condition: Condition): EventTrigger
	return newEvent(condition, false, {})
end

-- a state: from when the condition turns true until it turns false
Module.active = function(condition: Condition): StateTrigger
	return newState({ table.freeze({ Condition = condition, IsActive = true }) })
end

-- a state: for as long as the condition is false
Module.inactive = function(condition: Condition): StateTrigger
	return newState({ table.freeze({ Condition = condition, IsActive = false }) })
end

-- a state that takes every one of the states to be on at once
Module.all = function(...: StateTrigger): StateTrigger
	local requirements: { Requirement } = {}
	for _, trigger in { ... } do
		table.move(trigger.Requirements, 1, #trigger.Requirements, #requirements + 1, requirements)
	end
	return newState(requirements)
end

-- an event that only counts while every one of the states is on
Module.during = function(event: EventTrigger, ...: StateTrigger): EventTrigger
	local requirements = table.clone(event.Requirements)
	for _, trigger in { ... } do
		table.move(trigger.Requirements, 1, #trigger.Requirements, #requirements + 1, requirements)
	end
	return newEvent(event.Condition, event.IsStarted, requirements)
end

-- the machine arrives in the state of the binding
Module.entered = function(): EventTrigger
	return Module.started(AbilityCondition.current())
end

-- the machine leaves the state of the binding
Module.exited = function(): EventTrigger
	return Module.stopped(AbilityCondition.current())
end

-- for as long as the machine is in the state of the binding
Module.always = function(): StateTrigger
	return Module.active(AbilityCondition.current())
end

-- the machine has spent this many seconds in the state of the binding
Module.after = function(duration: number): EventTrigger
	return Module.started(AbilityCondition.elapsed(duration))
end

return Module
