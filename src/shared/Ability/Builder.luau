--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type Reach = VFXType.Reach
type ClientOptions = VFXType.ClientOptions
type Replication = VFXType.Replication
type Layout = AbilityType.Layout<any>
type ClientContext = AbilityType.ClientContext
type ServerContext = AbilityType.ServerContext
type Definition = AbilityType.Definition<any>
type EventHook = AbilityType.EventHook<any>
type StateHook = AbilityType.StateHook<any>
-- any binding that fires + any that's held, whatever sets it off
type Event = { Kind: "Event", Name: string }
type State = { Kind: "State", Name: string }
-- one half of an ability, put together a hook at a time: what this side does at the bindings of the layout. how far
-- an effect is shown + to whom is said here, with the binding it's hooked onto, never by the effect. a binding
-- nothing is hooked onto still moves the machine. a builder never changes: every method hands back a new one with the
-- hook on top, so what a factory hands out can be cleared, changed + built onto without touching what anybody else
-- got from it
export type ClientBuilder = {
	-- fires one effect as the binding does
	Fire: <P, R>(
		self: ClientBuilder,
		binding: Event,
		vfx: { Kind: "Event", IsClientSide: true, _Signature: (P) -> R },
		getProps: (context: ClientContext) -> P,
		options: ClientOptions?
	) -> ClientBuilder,
	-- holds one effect for as long as the binding is on
	Run: <P>(
		self: ClientBuilder,
		binding: State,
		vfx: { Kind: "State", IsClientSide: true, _Signature: (P) -> () },
		getProps: (context: ClientContext) -> P,
		options: ClientOptions?
	) -> ClientBuilder,
	-- does whatever it's handed as the binding fires
	On: (self: ClientBuilder, binding: Event, run: (context: ClientContext) -> ()) -> ClientBuilder,
	-- holds whatever it's handed for as long as the binding is on
	While: (
		self: ClientBuilder,
		binding: State,
		start: (context: ClientContext, swap: Swap?) -> Cleanup
	) -> ClientBuilder,
	-- gets a say in whether the binding fires on this side at all
	Guard: (self: ClientBuilder, binding: Event, guard: (context: ClientContext) -> boolean) -> ClientBuilder,
	-- puts right what this half did at a binding the client has the say on, once the server turned it down. the
	-- machine goes back to where the server is by itself, this is for what a state doesn't hold: a jump, a push
	Undo: (self: ClientBuilder, binding: Event, undo: (context: ClientContext) -> ()) -> ClientBuilder,
	-- drops whatever this half hooked onto the binding so far
	Clear: (self: ClientBuilder, binding: Event | State) -> ClientBuilder,
	Build: (self: ClientBuilder) -> AbilityType.ClientDefinition,
}
export type ServerBuilder = {
	Fire: <P, R>(
		self: ServerBuilder,
		binding: Event,
		vfx: { Kind: "Event", IsServerSide: true, _Signature: (P) -> R },
		getProps: (context: ServerContext) -> P
	) -> ServerBuilder,
	Run: <P>(
		self: ServerBuilder,
		binding: State,
		vfx: { Kind: "State", IsServerSide: true, _Signature: (P) -> () },
		getProps: (context: ServerContext) -> P
	) -> ServerBuilder,
	-- has the clients the replication picks show one effect as the binding fires
	FireClient: <P>(
		self: ServerBuilder,
		binding: Event,
		vfx: { Kind: "Event", Realm: "Client", _Signature: (P) -> nil },
		getProps: (context: ServerContext) -> P,
		replication: Replication?
	) -> ServerBuilder,
	-- has the clients the replication picks hold one effect for as long as the binding is on
	RunClient: <P>(
		self: ServerBuilder,
		binding: State,
		vfx: { Kind: "State", Realm: "Client", _Signature: (P) -> () },
		getProps: (context: ServerContext) -> P,
		replication: Replication?
	) -> ServerBuilder,
	On: (self: ServerBuilder, binding: Event, run: (context: ServerContext) -> ()) -> ServerBuilder,
	While: (
		self: ServerBuilder,
		binding: State,
		start: (context: ServerContext, swap: Swap?) -> Cleanup
	) -> ServerBuilder,
	Guard: (self: ServerBuilder, binding: Event, guard: (context: ServerContext) -> boolean) -> ServerBuilder,
	-- lets the machine of the player pass a client effect on to everybody else as the client half uses it on
	-- their own avatar
	Relay: (self: ServerBuilder, vfx: { Realm: "Client", Name: string }, reach: Reach?) -> ServerBuilder,
	Clear: (self: ServerBuilder, binding: Event | State) -> ServerBuilder,
	Build: (self: ServerBuilder) -> AbilityType.ServerDefinition,
}
-- Constants
local DEFAULT_REACH: Reach = table.freeze({})
-- Variables
-- References
-- Private Functions
-- the hooks of one binding swapped out, everything else is shared with what it was copied from
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
	local layout = definition.Layout

	local function check(binding: Event | State)
		assert(layout.Bindings[binding.Name] == binding, `"{binding.Name}" isn't a binding of "{layout.Id}"`)
	end

	local function addEvent(binding: Event, hook: EventHook): any
		check(binding)
		local hooks = table.clone(definition.EventHooks[binding.Name] or {})
		table.insert(hooks, table.freeze(hook))
		return builder(table.freeze({
			Layout = layout,
			EventHooks = setHooks(definition.EventHooks, binding.Name, hooks),
			StateHooks = definition.StateHooks,
			Relays = definition.Relays,
		}))
	end

	local function addState(binding: State, hook: StateHook): any
		check(binding)
		local hooks = table.clone(definition.StateHooks[binding.Name] or {})
		table.insert(hooks, hook)
		return builder(table.freeze({
			Layout = layout,
			EventHooks = definition.EventHooks,
			StateHooks = setHooks(definition.StateHooks, binding.Name, hooks),
			Relays = definition.Relays,
		}))
	end

	return table.freeze({
		Fire = function(
			_: any,
			binding: Event,
			vfx: any,
			getProps: (context: any) -> any,
			options: ClientOptions?
		): any
			return addEvent(binding, {
				Run = function(context: any)
					context.VFX.fire(vfx, getProps(context), options)
				end,
			})
		end,
		Run = function(_: any, binding: State, vfx: any, getProps: (context: any) -> any, options: ClientOptions?): any
			return addState(binding, function(context: any, swap: Swap?): Cleanup
				return context.VFX.start(vfx, getProps(context), swap, options).Stop
			end)
		end,
		FireClient = function(
			_: any,
			binding: Event,
			vfx: any,
			getProps: (context: any) -> any,
			replication: Replication?
		): any
			return addEvent(binding, {
				Run = function(context: any)
					context.VFX.fireClient(vfx, getProps(context), replication)
				end,
			})
		end,
		RunClient = function(
			_: any,
			binding: State,
			vfx: any,
			getProps: (context: any) -> any,
			replication: Replication?
		): any
			return addState(binding, function(context: any, swap: Swap?): Cleanup
				return context.VFX.startClient(vfx, getProps(context), swap, replication).Stop
			end)
		end,
		On = function(_: any, binding: Event, run: (context: any) -> ()): any
			return addEvent(binding, { Run = run })
		end,
		While = function(_: any, binding: State, start: StateHook): any
			return addState(binding, start)
		end,
		Guard = function(_: any, binding: Event, guard: (context: any) -> boolean): any
			return addEvent(binding, { Guard = guard })
		end,
		Undo = function(_: any, binding: Event, undo: (context: any) -> ()): any
			return addEvent(binding, { Undo = undo })
		end,
		Relay = function(_: any, vfx: { Name: string }, reach: Reach?): any
			local relays = table.clone(definition.Relays)
			relays[vfx.Name] = reach or DEFAULT_REACH
			return builder(table.freeze({
				Layout = layout,
				EventHooks = definition.EventHooks,
				StateHooks = definition.StateHooks,
				Relays = table.freeze(relays),
			}))
		end,
		Clear = function(_: any, binding: Event | State): any
			check(binding)
			return builder(table.freeze({
				Layout = layout,
				EventHooks = setHooks(definition.EventHooks, binding.Name, nil),
				StateHooks = setHooks(definition.StateHooks, binding.Name, nil),
				Relays = definition.Relays,
			}))
		end,
		-- what a builder holds is frozen all the way down, so it's handed out as it is
		Build = function(_: any): Definition
			return definition
		end,
	})
end

local function new(layout: Layout): any
	return builder(table.freeze({
		Layout = layout,
		EventHooks = table.freeze({}),
		StateHooks = table.freeze({}),
		Relays = table.freeze({}),
	}))
end
-- Class
return {
	-- the half of an ability that runs on the client of the character it belongs to
	newClient = function(layout: Layout): ClientBuilder
		return new(layout)
	end,
	-- the half the server runs
	newServer = function(layout: Layout): ServerBuilder
		return new(layout)
	end,
}
