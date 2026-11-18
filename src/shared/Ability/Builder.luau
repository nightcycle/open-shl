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
type EventHook = AbilityType.EventHook<any>
type StateHook = AbilityType.StateHook<any>
-- any binding that fires + any that's held, whatever sets it off
type Event = { Kind: "Event", Name: string }
type State = { Kind: "State", Name: string }
-- one half of an ability, put together a hook at a time: what this side does at the bindings of the layout. how far
-- an effect is shown + to whom is said here, with the binding it's hooked onto, never by the effect. a binding
-- nothing is hooked onto still moves the machine. a factory hands one of these out, so what it made can be cleared,
-- changed + built onto before it's built
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
type BuilderImpl = {
	__index: BuilderImpl,
	[string]: any,
}
-- the one builder both of the typed ones are: what a hook is run with differs by side, how it's filed doesn't
type Builder = typeof(setmetatable(
	{} :: {
		_Layout: Layout,
		_EventHooks: { [string]: { EventHook } },
		_StateHooks: { [string]: { StateHook } },
		_Relays: { [string]: Reach },
	},
	{} :: BuilderImpl
))
-- Constants
local DEFAULT_REACH: Reach = table.freeze({})
-- Variables
-- References
-- Private Functions
local function check(self: Builder, binding: Event | State)
	assert(self._Layout.Bindings[binding.Name] == binding, `"{binding.Name}" isn't a binding of "{self._Layout.Id}"`)
end

local function addEvent(self: Builder, binding: Event, hook: EventHook): Builder
	check(self, binding)
	local hooks = self._EventHooks[binding.Name] or {}
	self._EventHooks[binding.Name] = hooks
	table.insert(hooks, table.freeze(hook))
	return self
end

local function addState(self: Builder, binding: State, hook: StateHook): Builder
	check(self, binding)
	local hooks = self._StateHooks[binding.Name] or {}
	self._StateHooks[binding.Name] = hooks
	table.insert(hooks, hook)
	return self
end
-- Class
local Builder = {} :: BuilderImpl
Builder.__index = Builder

function Builder.Fire(
	self: Builder,
	binding: Event,
	vfx: any,
	getProps: (context: any) -> any,
	options: ClientOptions?
): Builder
	return addEvent(self, binding, {
		Run = function(context: any)
			context.VFX.fire(vfx, getProps(context), options)
		end,
	})
end

function Builder.Run(
	self: Builder,
	binding: State,
	vfx: any,
	getProps: (context: any) -> any,
	options: ClientOptions?
): Builder
	return addState(self, binding, function(context: any, swap: Swap?): Cleanup
		return context.VFX.start(vfx, getProps(context), swap, options).Stop
	end)
end

function Builder.FireClient(
	self: Builder,
	binding: Event,
	vfx: any,
	getProps: (context: any) -> any,
	replication: Replication?
): Builder
	return addEvent(self, binding, {
		Run = function(context: any)
			context.VFX.fireClient(vfx, getProps(context), replication)
		end,
	})
end

function Builder.RunClient(
	self: Builder,
	binding: State,
	vfx: any,
	getProps: (context: any) -> any,
	replication: Replication?
): Builder
	return addState(self, binding, function(context: any, swap: Swap?): Cleanup
		return context.VFX.startClient(vfx, getProps(context), swap, replication).Stop
	end)
end

function Builder.On(self: Builder, binding: Event, run: (context: any) -> ()): Builder
	return addEvent(self, binding, { Run = run })
end

function Builder.While(self: Builder, binding: State, start: StateHook): Builder
	return addState(self, binding, start)
end

function Builder.Guard(self: Builder, binding: Event, guard: (context: any) -> boolean): Builder
	return addEvent(self, binding, { Guard = guard })
end

function Builder.Relay(self: Builder, vfx: { Name: string }, reach: Reach?): Builder
	self._Relays[vfx.Name] = reach or DEFAULT_REACH
	return self
end

function Builder.Clear(self: Builder, binding: Event | State): Builder
	check(self, binding)
	self._EventHooks[binding.Name] = nil
	self._StateHooks[binding.Name] = nil
	return self
end

function Builder.Build(self: Builder): any
	local eventHooks: { [string]: { EventHook } } = {}
	for name, hooks in self._EventHooks do
		eventHooks[name] = table.freeze(table.clone(hooks))
	end
	local stateHooks: { [string]: { StateHook } } = {}
	for name, hooks in self._StateHooks do
		stateHooks[name] = table.freeze(table.clone(hooks))
	end
	return table.freeze({
		Layout = self._Layout,
		EventHooks = table.freeze(eventHooks),
		StateHooks = table.freeze(stateHooks),
		Relays = table.freeze(table.clone(self._Relays)),
	})
end

local function new(layout: Layout): any
	return setmetatable({
		_Layout = layout,
		_EventHooks = {},
		_StateHooks = {},
		_Relays = {},
	}, Builder)
end

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
