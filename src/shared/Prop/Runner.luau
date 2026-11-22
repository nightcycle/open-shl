--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Aim = AbilityType.Aim
type Memory = AbilityType.Memory
type Cleanup = VFXType.Cleanup
type Definition = PropType.Definition<any>
type EventHook = PropType.EventHook<any>
type StateHook = PropType.StateHook<any>
export type Options = {
	-- makes what a hook is run with, out of what came with the click + what the runner remembers
	NewContext: (aim: Aim?, memory: Memory, record: Memory) -> any,
	-- seconds a use may be early by: the server's is, so a client that's on time isn't turned down over a hiccup of
	-- its connection
	Leniency: number?,
	-- told of every use this side let through, before any of its hooks ran
	OnUsed: ((aim: Aim?) -> ())?,
}
type RunnerImpl = {
	__index: RunnerImpl,
	Draw: (self: Runner) -> (),
	Stow: (self: Runner) -> (),
	Use: (self: Runner, aim: Aim?) -> boolean,
	Destroy: (self: Runner) -> (),
}
-- runs one half of a prop for one character: it's in the hand or it isn't, + in the hand it's being used or it
-- isn't. there's nothing else to keep
export type Runner = typeof(setmetatable(
	{} :: {
		IsAlive: boolean,
		Definition: Definition,
		IsHeld: boolean,
		IsUsing: boolean,
		_NewContext: (aim: Aim?, memory: Memory, record: Memory) -> any,
		_Leniency: number,
		_OnUsed: ((aim: Aim?) -> ())?,
		_Memory: Memory,
		_Record: Memory,
		-- when the next use may start, on the clock of os.clock. it's the runner's, not the hand's: putting the prop
		-- away + getting it back out doesn't bring a use any closer
		_NextUseTime: number,
		_UseAim: Aim?,
		_UseThread: thread?,
		_Cleanups: { [string]: { Cleanup } },
	},
	{} :: RunnerImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function newContext(self: Runner, aim: Aim?): any
	return self._NewContext(aim, self._Memory, self._Record)
end

-- a hook that errors is on whoever wrote it, the runner goes on
local function start(self: Runner, name: string, aim: Aim?)
	local hooks: { StateHook } = self.Definition.StateHooks[name] or {}
	local cleanups: { Cleanup } = {}
	self._Cleanups[name] = cleanups
	for _, hook in hooks do
		local success, result = xpcall(hook :: any, debug.traceback, newContext(self, aim))
		if success then
			table.insert(cleanups, result)
		else
			warn(`the "{name}" hook of "{self.Definition.Prop.Id}" failed: {result}`)
		end
	end
end

local function stop(self: Runner, name: string)
	local cleanups = self._Cleanups[name]
	self._Cleanups[name] = nil
	if cleanups then
		for _, cleanup in cleanups do
			task.spawn(cleanup, nil)
		end
	end
end

local function run(self: Runner, name: string, aim: Aim?)
	local hooks: { EventHook } = self.Definition.EventHooks[name] or {}
	local context = newContext(self, aim)
	for _, hook in hooks do
		if hook.Run then
			task.spawn(hook.Run, context)
		end
	end
end

-- whatever waits for the end of the use that's on isn't waited for any longer
local function cancel(self: Runner)
	local thread = self._UseThread
	self._UseThread = nil
	if thread then
		task.cancel(thread)
	end
end

-- the use that's on is over: what it showed goes, what waited at its end comes. the hand comes to rest unless the
-- next use is right behind it
local function finish(self: Runner, isResting: boolean)
	local aim = self._UseAim
	self._UseAim = nil
	cancel(self)
	self.IsUsing = false
	stop(self, "Using")
	if isResting then
		start(self, "Rest", aim)
	end
	run(self, "Finish", aim)
end
-- Class
local Runner = {} :: RunnerImpl
Runner.__index = Runner

-- it came into the hand
function Runner:Draw()
	if not self.IsAlive or self.IsHeld then
		return
	end
	self.IsHeld = true
	start(self, "Hold", nil)
	start(self, "Rest", nil)
	run(self, "Draw", nil)
end

-- it left the hand, whatever took it. a use that's cut short gives nothing: what waits at its end never comes
function Runner:Stow()
	if not self.IsAlive or not self.IsHeld then
		return
	end
	self.IsHeld = false
	self._UseAim = nil
	cancel(self)
	self.IsUsing = false
	stop(self, "Using")
	stop(self, "Rest")
	stop(self, "Hold")
	table.clear(self._Memory)
end

-- a click with it out. true if a use started: it's in the hand, it has a use, the last one is far enough back + no
-- guard turned it down. a use that's turned down costs nothing + locks nothing
function Runner:Use(aim: Aim?): boolean
	local rule = self.Definition.Prop.Use
	if not self.IsAlive or not self.IsHeld or not rule then
		return false
	end
	local now = os.clock()
	if now + self._Leniency < self._NextUseTime then
		return false
	end
	local hooks: { EventHook } = self.Definition.EventHooks["Use"] or {}
	local context = newContext(self, aim)
	for _, hook in hooks do
		if hook.Guard and not hook.Guard(context) then
			return false
		end
	end
	-- one that was let through a moment early finds the last one still on its last moment
	if self.IsUsing then
		finish(self, false)
	else
		stop(self, "Rest")
	end
	self._NextUseTime = now + (rule.Lockout or rule.Duration)
	if self._OnUsed then
		self._OnUsed(aim)
	end
	self.IsUsing = true
	self._UseAim = aim
	start(self, "Using", aim)
	run(self, "Use", aim)
	self._UseThread = task.delay(rule.Duration, function()
		-- the wait is over by itself, it's nobody's to cancel any more
		self._UseThread = nil
		if self.IsAlive and self.IsUsing then
			finish(self, true)
		end
	end)
	return true
end

function Runner:Destroy()
	if not self.IsAlive then
		return
	end
	self:Stow()
	self.IsAlive = false
	table.clear(self._Record)
end

return {
	new = function(definition: Definition, options: Options): Runner
		return setmetatable({
			IsAlive = true,
			Definition = definition,
			IsHeld = false,
			IsUsing = false,
			_NewContext = options.NewContext,
			_Leniency = options.Leniency or 0,
			_OnUsed = options.OnUsed,
			_Memory = {},
			_Record = {},
			_NextUseTime = 0,
			_UseAim = nil :: Aim?,
			_UseThread = nil :: thread?,
			_Cleanups = {},
		}, Runner)
	end,
}
