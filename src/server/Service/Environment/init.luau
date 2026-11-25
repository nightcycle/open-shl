--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local ScheduleUtil = require("@self/Schedule")
-- Types
type Season = EnvironmentDefinition.Season
type Weather = EnvironmentDefinition.Weather
type EnvironmentServiceImpl = {
	__index: EnvironmentServiceImpl,
	-- in hours, what a clock on the wall of this server reads
	GetClockTime: (self: EnvironmentService) -> number,
	GetIfNight: (self: EnvironmentService) -> boolean,
	GetSeason: (self: EnvironmentService) -> Season,
	GetWeather: (self: EnvironmentService) -> Weather,
}
export type EnvironmentService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the weather was rolled, the season may have turned with it
		Changed: Signal.Signal<>,
		-- on the clock of the server, when its own read the hour it starts at
		_StartedAt: number,
		_State: ScheduleUtil.State,
		_Random: Random,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: EnvironmentServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- the season goes out before the count of them: a client that's told of the count draws the season it has by then
local function write(self: EnvironmentService)
	AttributeDefinition.set(Workspace, AttributeDefinition.Season, self._State.Season)
	AttributeDefinition.set(Workspace, AttributeDefinition.SeasonsPassed, self._State.SeasonsPassed)
	AttributeDefinition.set(Workspace, AttributeDefinition.Weather, self._State.Weather)
end

-- yields for as long as the service lives. it sleeps from one roll to the next, the hours in between are nobody's
-- to count: whoever wants the time works it out
local function run(self: EnvironmentService)
	local rollNumber = 1
	while true do
		local rollAt = self._StartedAt + ScheduleUtil.getRollAt(rollNumber)
		-- a wait is over when the scheduler gets to it, which the clock of the server may not agree is late enough
		while Workspace:GetServerTimeNow() < rollAt do
			task.wait(rollAt - Workspace:GetServerTimeNow())
		end
		self._State = ScheduleUtil.step(self._State, rollNumber, self._Random)
		write(self)
		self.Changed:Fire()
		rollNumber += 1
	end
end
-- Class
local EnvironmentService = {} :: EnvironmentServiceImpl
EnvironmentService.__index = EnvironmentService

function EnvironmentService:GetClockTime(): number
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentDefinition.getClockTime(self._StartedAt, Workspace:GetServerTimeNow())
end

function EnvironmentService:GetIfNight(): boolean
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentDefinition.getIfNight(self:GetClockTime())
end

function EnvironmentService:GetSeason(): Season
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return self._State.Season
end

function EnvironmentService:GetWeather(): Weather
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return self._State.Weather
end

-- the server keeps the time, the season + the weather + draws none of them: the sky, the ground, the trees + the
-- windows of its own copy of the place stay the way the map has them. every client draws what's said here for itself
return ServiceLocker(function(): EnvironmentService
	local self = setmetatable({
		IsInitialized = true :: true,
		Changed = Signal.new() :: Signal.Signal<>,
		_StartedAt = Workspace:GetServerTimeNow(),
		_State = ScheduleUtil.new(),
		_Random = Random.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, EnvironmentService)

	AttributeDefinition.set(Workspace, AttributeDefinition.ClockStartedAt, self._StartedAt)
	write(self)

	local scheduleThread = task.spawn(run, self)
	table.insert(self._CleanUpCallbacks, function()
		task.cancel(scheduleThread)
	end)

	return self
end, function(self: EnvironmentService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
