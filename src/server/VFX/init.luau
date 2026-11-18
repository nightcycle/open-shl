--!strict
-- Services
-- Packages
-- Modules
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Validator = VFXType.Validator
type Cleanup = VFXType.Cleanup
type Swap = VFXType.Swap
type ServerScope = VFXType.ServerScope
type ServerEvent<P, R> = VFXType.ServerEvent<P, R>
type ServerState<P> = VFXType.ServerState<P>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- a server effect is where something becomes true for everybody: health, energy, what stands in the world. clients
-- never hear its name, only what it has them show
Module.newEvent = function<P, R>(name: string, props: Validator, run: (props: P, scope: ServerScope) -> R): ServerEvent<P, R>
	return table.freeze({
		Name = name,
		Realm = "Server" :: "Server",
		Kind = "Event" :: "Event",
		IsServerSide = true :: true,
		Props = props,
		Run = run,
	}) :: any
end

Module.newState = function<P>(
	name: string,
	props: Validator,
	start: (props: P, scope: ServerScope, swap: Swap?) -> Cleanup
): ServerState<P>
	return table.freeze({
		Name = name,
		Realm = "Server" :: "Server",
		Kind = "State" :: "State",
		IsServerSide = true :: true,
		Props = props,
		Start = start,
	}) :: any
end

return Module
