--!strict
-- Services
-- Packages
-- Modules
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Cleanup = VFXType.Cleanup
type ClientOptions = VFXType.ClientOptions
type Replication = VFXType.Replication
type PropDefinition = PropType.PropDefinition
type ClientContext = PropType.ClientContext
type ServerContext = PropType.ServerContext
type Definition = PropType.Definition<any>
type EventHook = PropType.EventHook<any>
type StateHook = PropType.StateHook<any>
type Event = PropType.EventMoment
type State = PropType.StateMoment
-- one half of a prop, put together a hook at a time: what this side does at each of the moments every prop has. how far
-- an effect is shown + to whom is said here, with the moment it's hooked onto, never by the effect. a builder never
-- changes: every method hands back a new one with the hook on top, so what a factory hands out can be cleared, changed
-- + built onto without touching what anybody else got from it
export type ClientBuilder = {
	-- fires one effect as the moment comes
	Fire: <P, R>(
		self: ClientBuilder,
		moment: Event,
		vfx: { Kind: "Event", IsClientSide: true, _Signature: (P) -> R },
		getProps: (context: ClientContext) -> P,
		options: ClientOptions?
	) -> ClientBuilder,
	-- holds one effect for as long as the moment lasts
	Run: <P>(
		self: ClientBuilder,
		moment: State,
		vfx: { Kind: "State", IsClientSide: true, _Signature: (P) -> () },
		getProps: (context: ClientContext) -> P,
		options: ClientOptions?
	) -> ClientBuilder,
	-- does whatever it's handed as the moment comes
	On: (self: ClientBuilder, moment: Event, run: (context: ClientContext) -> ()) -> ClientBuilder,
	-- holds whatever it's handed for as long as the moment lasts
	While: (self: ClientBuilder, moment: State, start: (context: ClientContext) -> Cleanup) -> ClientBuilder,
	-- gets a say in whether a use starts on this side at all
	Guard: (self: ClientBuilder, guard: (context: ClientContext) -> boolean) -> ClientBuilder,
	-- drops whatever this half hooked onto the moment so far
	Clear: (self: ClientBuilder, moment: Event | State) -> ClientBuilder,
	Build: (self: ClientBuilder) -> PropType.ClientDefinition,
}
export type ServerBuilder = {
	Fire: <P, R>(
		self: ServerBuilder,
		moment: Event,
		vfx: { Kind: "Event", IsServerSide: true, _Signature: (P) -> R },
		getProps: (context: ServerContext) -> P
	) -> ServerBuilder,
	Run: <P>(
		self: ServerBuilder,
		moment: State,
		vfx: { Kind: "State", IsServerSide: true, _Signature: (P) -> () },
		getProps: (context: ServerContext) -> P
	) -> ServerBuilder,
	-- has the clients the replication picks show one effect as the moment comes
	FireClient: <P>(
		self: ServerBuilder,
		moment: Event,
		vfx: { Kind: "Event", Realm: "Client", _Signature: (P) -> nil },
		getProps: (context: ServerContext) -> P,
		replication: Replication?
	) -> ServerBuilder,
	-- has the clients the replication picks hold one effect for as long as the moment lasts
	RunClient: <P>(
		self: ServerBuilder,
		moment: State,
		vfx: { Kind: "State", Realm: "Client", _Signature: (P) -> () },
		getProps: (context: ServerContext) -> P,
		replication: Replication?
	) -> ServerBuilder,
	On: (self: ServerBuilder, moment: Event, run: (context: ServerContext) -> ()) -> ServerBuilder,
	While: (self: ServerBuilder, moment: State, start: (context: ServerContext) -> Cleanup) -> ServerBuilder,
	Guard: (self: ServerBuilder, guard: (context: ServerContext) -> boolean) -> ServerBuilder,
	Clear: (self: ServerBuilder, moment: Event | State) -> ServerBuilder,
	Build: (self: ServerBuilder) -> PropType.ServerDefinition,
}
-- Constants
-- the moments only a prop with a use ever gets to
local USE_MOMENT_NAMES: { [string]: boolean } = table.freeze({ Use = true, Using = true, Finish = true })
-- Variables
-- References
-- Private Functions
-- the hooks of one moment swapped out, everything else is shared with what it was copied from
local function setHooks<H>(hooksByName: { [string]: { H } }, name: string, hooks: { H }?): { [string]: { H } }
	local out = table.clone(hooksByName)
	out[name] = nil
	if hooks then
		out[name] = table.freeze(hooks)
	end
	return table.freeze(out)
end

-- the one builder both of the typed ones are: what a hook is run with differs by side, how it's filed doesn't
local function builder(definition: Definition): any
	local prop = definition.Prop

	local function check(moment: Event | State)
		assert((PropMoment :: any)[moment.Name] == moment, `"{moment.Name}" isn't a moment of a prop`)
		-- a hook on what never comes would sit there for good without a word
		assert(prop.Use ~= nil or not USE_MOMENT_NAMES[moment.Name], `"{prop.Id}" has no use for "{moment.Name}"`)
	end

	local function addEvent(moment: Event, hook: EventHook): any
		check(moment)
		local hooks = table.clone(definition.EventHooks[moment.Name] or {})
		table.insert(hooks, table.freeze(hook))
		return builder(table.freeze({
			Prop = prop,
			EventHooks = setHooks(definition.EventHooks, moment.Name, hooks),
			StateHooks = definition.StateHooks,
		}))
	end

	local function addState(moment: State, hook: StateHook): any
		check(moment)
		local hooks = table.clone(definition.StateHooks[moment.Name] or {})
		table.insert(hooks, hook)
		return builder(table.freeze({
			Prop = prop,
			EventHooks = definition.EventHooks,
			StateHooks = setHooks(definition.StateHooks, moment.Name, hooks),
		}))
	end

	return table.freeze({
		Fire = function(_: any, moment: Event, vfx: any, getProps: (context: any) -> any, options: ClientOptions?): any
			return addEvent(moment, {
				Run = function(context: any)
					context.VFX.fire(vfx, getProps(context), options)
				end,
			})
		end,
		Run = function(_: any, moment: State, vfx: any, getProps: (context: any) -> any, options: ClientOptions?): any
			return addState(moment, function(context: any): Cleanup
				return context.VFX.start(vfx, getProps(context), nil, options).Stop
			end)
		end,
		FireClient = function(
			_: any,
			moment: Event,
			vfx: any,
			getProps: (context: any) -> any,
			replication: Replication?
		): any
			return addEvent(moment, {
				Run = function(context: any)
					context.VFX.fireClient(vfx, getProps(context), replication)
				end,
			})
		end,
		RunClient = function(
			_: any,
			moment: State,
			vfx: any,
			getProps: (context: any) -> any,
			replication: Replication?
		): any
			return addState(moment, function(context: any): Cleanup
				return context.VFX.startClient(vfx, getProps(context), nil, replication).Stop
			end)
		end,
		On = function(_: any, moment: Event, run: (context: any) -> ()): any
			return addEvent(moment, { Run = run })
		end,
		While = function(_: any, moment: State, start: StateHook): any
			return addState(moment, start)
		end,
		-- only a use is anybody's to turn down: nothing asks before a hand closes or a bite is over
		Guard = function(_: any, guard: (context: any) -> boolean): any
			return addEvent(PropMoment.Use, { Guard = guard })
		end,
		Clear = function(_: any, moment: Event | State): any
			check(moment)
			return builder(table.freeze({
				Prop = prop,
				EventHooks = setHooks(definition.EventHooks, moment.Name, nil),
				StateHooks = setHooks(definition.StateHooks, moment.Name, nil),
			}))
		end,
		-- what a builder holds is frozen all the way down, so it's handed out as it is
		Build = function(_: any): Definition
			return definition
		end,
	})
end

local function new(prop: PropDefinition): any
	return builder(table.freeze({
		Prop = prop,
		EventHooks = table.freeze({}),
		StateHooks = table.freeze({}),
	}))
end
-- Class
return {
	-- the half of a prop that runs on the client of the character that holds it
	newClient = function(prop: PropDefinition): ClientBuilder
		return new(prop)
	end,
	-- the half the server runs
	newServer = function(prop: PropDefinition): ServerBuilder
		return new(prop)
	end,
}
