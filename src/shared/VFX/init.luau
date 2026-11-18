--!strict
-- Services
-- Packages
-- Modules
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Validator = VFXType.Validator
type Cleanup = VFXType.Cleanup
type Swap = VFXType.Swap
type SharedScope = VFXType.SharedScope
type SharedEvent<P, R> = VFXType.SharedEvent<P, R>
type SharedState<P> = VFXType.SharedState<P>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- a shared effect is the same code on both sides of the network: what has to come out the same wherever it's asked.
-- it isn't sent anywhere, it runs where it's fired
Module.newEvent = function<P, R>(name: string, props: Validator, run: (props: P, scope: SharedScope) -> R): SharedEvent<P, R>
	return table.freeze({
		Name = name,
		Realm = "Shared" :: "Shared",
		Kind = "Event" :: "Event",
		IsClientSide = true :: true,
		IsServerSide = true :: true,
		Props = props,
		Run = run,
	}) :: any
end

Module.newState = function<P>(
	name: string,
	props: Validator,
	start: (props: P, scope: SharedScope, swap: Swap?) -> Cleanup
): SharedState<P>
	return table.freeze({
		Name = name,
		Realm = "Shared" :: "Shared",
		Kind = "State" :: "State",
		IsClientSide = true :: true,
		IsServerSide = true :: true,
		Props = props,
		Start = start,
	}) :: any
end

return Module
