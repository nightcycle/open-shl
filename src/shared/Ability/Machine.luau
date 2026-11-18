--!strict
-- Services
-- Packages
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local ConditionStore = require("@game/ReplicatedStorage/Shared/Ability/ConditionStore")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Signal<T...> = Signal.Signal<T...>
type ConditionStore = ConditionStore.ConditionStore
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type Aim = AbilityType.Aim
type Stimulus = AbilityType.Stimulus
type Requirement = AbilityType.Requirement
type Memory = AbilityType.Memory
type Binding = AbilityType.Binding
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type EventHook = AbilityType.EventHook<any>
type StateHook = AbilityType.StateHook<any>
-- the machine doesn't care what a hook is run with, whoever builds the definition does
type Definition = AbilityType.Definition<any>
export type Realm = "Client" | "Server"
export type Options = {
	Realm: Realm,
	Store: ConditionStore,
	-- makes what a hook is run with, out of what set its binding off + what the machine remembers: of the state
	-- it's in + for good
	NewContext: (stimulus: Stimulus?, memory: Memory, record: Memory) -> any,
	-- seconds the clock of the machine runs ahead: the server's does, so a client that's on time isn't turned down
	-- over a hiccup of its connection
	Leniency: number?,
	-- told of every binding this side has the say on as it fires, from the very first one
	OnFired: ((binding: EventBinding, stimulus: Stimulus) -> ())?,
}
type MachineImpl = {
	__index: MachineImpl,
	Raise: (self: Machine, name: string, payload: unknown, aim: Aim?) -> (),
	Fire: (self: Machine, name: string, payload: unknown, aim: Aim?) -> (),
	SetStateId: (self: Machine, stateId: string) -> (),
	Destroy: (self: Machine) -> (),
}
-- runs one half of an ability for one character: keeps the state + sets the bindings of it off as the conditions
-- change, each with whatever the half hooked onto it
export type Machine = typeof(setmetatable(
	{} :: {
		IsAlive: boolean,
		Definition: Definition,
		Realm: Realm,
		Store: ConditionStore,
		StateId: string,
		StateChanged: Signal<string, string>, -- the state it's in now, the one it left
		-- a binding this side has the say on fired, the other side is waiting to hear of it
		Fired: Signal<EventBinding, Stimulus>,
		_NewContext: (stimulus: Stimulus?, memory: Memory, record: Memory) -> any,
		_Leniency: number,
		_Bindings: { [string]: { Binding } }, -- by state, in the order of their names
		_Memory: Memory,
		_Record: Memory,
		_Aim: Aim?, -- what came with whatever brought the machine into the state it's in
		_EnterTime: number,
		_Epoch: number, -- goes up with every state, a timer of an earlier one finds it moved on
		_Cleanups: { [StateBinding]: { Cleanup } },
		_Queue: { Stimulus },
		_IsFlushing: boolean,
		_CleanUpCallbacks: { () -> () },
	},
	{} :: MachineImpl
))
-- Constants
local CURRENT_KEY = AbilityCondition.current().Key
-- what a stimulus that's meant for one binding goes by, no condition is stored under it
local BINDING_KEY = "Binding"
-- Variables
-- References
-- Private Functions
local function getIfHolds(self: Machine, requirements: { Requirement }): boolean
	for _, requirement in requirements do
		local condition = requirement.Condition
		local isActive: boolean
		if condition.Type == "Current" then
			isActive = true
		elseif condition.Type == "Elapsed" then
			isActive = os.clock() - self._EnterTime + self._Leniency >= condition.Duration
		else
			isActive = self.Store:Get(condition.Key)
		end
		if isActive ~= requirement.IsActive then
			return false
		end
	end
	return true
end

-- a binding that's set off by nothing a player points with, like time passing, still knows where they pointed as
-- they got the machine into its state
local function newContext(self: Machine, stimulus: Stimulus?): any
	local aim = self._Aim
	if not aim or (stimulus and stimulus.Aim) then
		return self._NewContext(stimulus, self._Memory, self._Record)
	end
	return self._NewContext(
		table.freeze({
			Key = if stimulus then stimulus.Key else CURRENT_KEY,
			IsActive = if stimulus then stimulus.IsActive else true,
			Aim = aim,
			Payload = if stimulus then stimulus.Payload else nil,
			BindingName = if stimulus then stimulus.BindingName else nil,
			IsRemote = if stimulus then stimulus.IsRemote else nil,
		}),
		self._Memory,
		self._Record
	)
end

-- a hook that errors is on whoever wrote it, the machine goes on
local function start(self: Machine, binding: StateBinding, swap: Swap?)
	local cleanups: { Cleanup } = {}
	local hooks: { StateHook } = self.Definition.StateHooks[binding.Name] or {}
	for _, hook in hooks do
		local success, cleanup = pcall(hook, newContext(self, nil), swap)
		if success then
			table.insert(cleanups, cleanup)
		else
			warn(`"{binding.Name}" of "{self.Definition.Layout.Id}" didn't start: {cleanup}`)
		end
	end
	self._Cleanups[binding] = cleanups
end

local function stop(self: Machine, binding: StateBinding, swap: Swap?)
	local cleanups: { Cleanup } = self._Cleanups[binding] or {}
	self._Cleanups[binding] = nil
	for _, cleanup in cleanups do
		task.spawn(cleanup, swap)
	end
end

-- turns the state bindings of the current state on + off to match what they require
local function refresh(self: Machine, swap: Swap?)
	for _, binding in self._Bindings[self.StateId] do
		if binding.Kind ~= "State" then
			continue
		end
		local isOn = self._Cleanups[binding] ~= nil
		local isRequired = getIfHolds(self, binding.Trigger.Requirements)
		if isRequired and not isOn then
			start(self, binding, swap)
		elseif isOn and not isRequired then
			stop(self, binding, nil)
		end
	end
end

local function getIfSetOff(self: Machine, binding: EventBinding, stimulus: Stimulus): boolean
	if stimulus.BindingName then
		if stimulus.BindingName ~= binding.Name then
			return false
		end
		-- the other side only gets to fire what's its to decide, this one only raises what's waiting for it
		if stimulus.IsRemote then
			return binding.Authority ~= "Both" and binding.Authority ~= self.Realm
		end
		return binding.Trigger == nil and binding.Authority == self.Realm
	end
	local trigger = binding.Trigger
	if not trigger or (binding.Authority ~= "Both" and binding.Authority ~= self.Realm) then
		return false
	end
	return trigger.Condition.Key == stimulus.Key
		and trigger.IsStarted == stimulus.IsActive
		and getIfHolds(self, trigger.Requirements)
end

-- runs every event binding of the current state the stimulus sets off. the first of them that moves the machine
-- is handed back
local function fire(self: Machine, stimulus: Stimulus): EventBinding?
	local id = self.Definition.Layout.Id
	local leadingBinding: EventBinding? = nil
	for _, binding in self._Bindings[self.StateId] do
		if binding.Kind ~= "Event" or not getIfSetOff(self, binding, stimulus) then
			continue
		end
		if stimulus.IsRemote then
			local success, msg = binding.Payload(stimulus.Payload)
			if not success then
				warn(`dropped "{binding.Name}" of "{id}": {msg}`)
				continue
			end
		end
		local context = newContext(self, stimulus)
		local hooks: { EventHook } = self.Definition.EventHooks[binding.Name] or {}
		local isAllowed = true
		for _, hook in hooks do
			if not hook.Guard then
				continue
			end
			local success, result = pcall(hook.Guard, context)
			if not success then
				warn(`a guard of "{binding.Name}" of "{id}" failed: {result}`)
			end
			if not success or not result then
				isAllowed = false
				break
			end
		end
		if not isAllowed then
			continue
		end
		for _, hook in hooks do
			if hook.Run then
				task.spawn(hook.Run, context)
			end
		end
		if binding.Authority == self.Realm then
			self.Fired:Fire(binding, stimulus)
		end
		-- one that leads to the state it's in starts that state over
		if binding.To and not leadingBinding then
			leadingBinding = binding
		end
	end
	return leadingBinding
end

local push: (self: Machine, stimulus: Stimulus) -> ()

local function enter(self: Machine, stateId: string, swap: Swap?)
	local store = self.Store
	local id = self.Definition.Layout.Id
	local previousId = self.StateId
	self._Epoch += 1
	self._EnterTime = os.clock()
	self._Memory = {}
	self.StateId = stateId
	if previousId ~= stateId then
		store:Set(AbilityCondition.abilityState(id, previousId).Key, false)
	end
	store:Set(AbilityCondition.abilityState(id, stateId).Key, true)
	refresh(self, swap)
	-- whatever waits for time to pass in this state is woken up once it has
	local epoch = self._Epoch
	local keys: { [number]: string } = {}
	for _, binding in self._Bindings[stateId] do
		local requirements: { Requirement } = {}
		if binding.Kind == "State" then
			requirements = binding.Trigger.Requirements
		elseif binding.Trigger then
			requirements = binding.Trigger.Requirements
			if binding.Trigger.Condition.Type == "Elapsed" then
				keys[binding.Trigger.Condition.Duration] = binding.Trigger.Condition.Key
			end
		end
		for _, requirement in requirements do
			if requirement.Condition.Type == "Elapsed" then
				keys[requirement.Condition.Duration] = requirement.Condition.Key
			end
		end
	end
	for duration, key in keys do
		task.delay(math.max(0, duration - self._Leniency), function()
			if self.IsAlive and self._Epoch == epoch then
				push(self, table.freeze({ Key = key, IsActive = true }))
			end
		end)
	end
	push(self, table.freeze({ Key = CURRENT_KEY, IsActive = true }))
	if previousId ~= stateId then
		self.StateChanged:Fire(stateId, previousId)
	end
end

-- a binding that's in the next state as well runs on as if nothing happened
local function leave(self: Machine, swap: Swap, nextStateId: string)
	fire(self, table.freeze({ Key = CURRENT_KEY, IsActive = false }))
	for binding in self._Cleanups do
		if not table.find(binding.StateIds, nextStateId) then
			stop(self, binding, swap)
		end
	end
end

-- one stimulus at a time: a hook that changes a condition mid-way is dealt with once this one is done
local function flush(self: Machine)
	if self._IsFlushing then
		return
	end
	self._IsFlushing = true
	while self.IsAlive and #self._Queue > 0 do
		local nextStimulus = table.remove(self._Queue, 1) :: Stimulus
		local binding = fire(self, nextStimulus)
		local stateId = binding and binding.To
		if binding and stateId then
			-- time moving the machine on doesn't make it forget where its player pointed
			self._Aim = nextStimulus.Aim or self._Aim
			local swap: Swap = table.freeze({
				From = self.StateId,
				To = stateId,
				Duration = binding.Duration or 0,
			})
			leave(self, swap, stateId)
			enter(self, stateId, swap)
		else
			refresh(self, nil)
		end
	end
	self._IsFlushing = false
end

function push(self: Machine, stimulus: Stimulus)
	table.insert(self._Queue, stimulus)
	flush(self)
end
-- Class
local Machine = {} :: MachineImpl
Machine.__index = Machine

-- for a hook of this half: fires a binding that waits for its word
function Machine:Raise(name: string, payload: unknown, aim: Aim?)
	if self.IsAlive then
		push(
			self,
			table.freeze({ Key = BINDING_KEY, IsActive = true, Aim = aim, Payload = payload, BindingName = name })
		)
	end
end

-- for the other side: fires a binding it has the say on. it's dropped if the machine isn't in a state for it or the
-- payload isn't what the binding takes, what this half hooked onto it still gets to turn it down
function Machine:Fire(name: string, payload: unknown, aim: Aim?)
	if self.IsAlive then
		push(
			self,
			table.freeze({
				Key = BINDING_KEY,
				IsActive = true,
				Aim = aim,
				Payload = payload,
				BindingName = name,
				IsRemote = true,
			})
		)
	end
end

-- puts the machine where it's told to be, no questions asked
function Machine:SetStateId(stateId: string)
	if not self.IsAlive or self.StateId == stateId then
		return
	end
	assert(self._Bindings[stateId], `"{self.Definition.Layout.Id}" has no state "{stateId}"`)
	local swap: Swap = table.freeze({
		From = self.StateId,
		To = stateId,
		Duration = 0,
	})
	-- whatever the hooks of the two states set off on the way waits until the machine has arrived
	local wasFlushing = self._IsFlushing
	self._IsFlushing = true
	leave(self, swap, stateId)
	self._Aim = nil
	enter(self, stateId, swap)
	self._IsFlushing = wasFlushing
	flush(self)
end

function Machine:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	for binding in self._Cleanups do
		stop(self, binding, nil)
	end
	self.Store:Set(AbilityCondition.abilityState(self.Definition.Layout.Id, self.StateId).Key, false)
	self.StateChanged:Destroy()
	self.Fired:Destroy()
	table.clear(self._Queue)
end

return {
	new = function(definition: Definition, options: Options): Machine
		local layout = definition.Layout
		local bindings: { [string]: { Binding } } = { [layout.InitialStateId] = {} }
		for _, binding: Binding in layout.Bindings do
			local stateIds: { string } = (binding :: any).StateIds
			for _, stateId in stateIds do
				bindings[stateId] = bindings[stateId] or {}
				table.insert(bindings[stateId], binding)
			end
		end
		-- a table of bindings has no order of its own, their names give the machine one that's the same on both sides
		for _, list in bindings do
			table.sort(list, function(a: Binding, b: Binding): boolean
				return a.Name < b.Name
			end)
		end
		local self = setmetatable({
			IsAlive = true,
			Definition = definition,
			Realm = options.Realm,
			Store = options.Store,
			StateId = layout.InitialStateId,
			StateChanged = Signal.new(),
			Fired = Signal.new(),
			_NewContext = options.NewContext,
			_Leniency = options.Leniency or 0,
			_Bindings = bindings,
			_Memory = {},
			_Record = {},
			_Aim = nil :: Aim?,
			_EnterTime = os.clock(),
			_Epoch = 0,
			_Cleanups = {},
			_Queue = {},
			_IsFlushing = false,
			_CleanUpCallbacks = {},
		}, Machine)
		if options.OnFired then
			self.Fired:Connect(options.OnFired)
		end
		local connection = options.Store.Changed:Connect(function(stimulus: Stimulus)
			push(self, stimulus)
		end)
		table.insert(self._CleanUpCallbacks, function()
			connection:Disconnect()
		end)
		enter(self, layout.InitialStateId, nil)
		return self
	end,
}
