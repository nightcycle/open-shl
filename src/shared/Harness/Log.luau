--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local Plain = require("@game/ReplicatedStorage/Shared/Harness/Plain")
-- Types
local HarnessTypes = require("@game/ReplicatedStorage/Shared/Harness/Types")
type Event = HarnessTypes.Event
-- what an event has to be to be picked out. every field of Where has to be what the data of the event has under it
export type Filter = {
	Kind: string?,
	Subject: string?,
	Where: { [string]: any }?,
}
type LogImpl = {
	__index: LogImpl,
	-- the number of the newest event, 0 before the first
	GetLast: (self: Log) -> number,
	-- the number of the oldest event that's still kept, one past the newest when none is
	GetFirst: (self: Log) -> number,
	Add: (self: Log, kind: string, subject: string?, data: { [string]: any }?) -> (),
	-- every event that's kept, came after the one of that number + passes the filter, oldest first
	Read: (self: Log, since: number, filter: Filter) -> { Event },
	-- yields until one that came after the one of that number passes the filter. nil once the seconds are up
	Wait: (self: Log, since: number, filter: Filter, timeout: number) -> Event?,
}
export type Log = typeof(setmetatable(
	{} :: {
		_Capacity: number,
		_Last: number,
		-- by their number, the ones that fell out of the back are taken out
		_Events: { [number]: Event },
	},
	{} :: LogImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function getIfPassed(event: Event, filter: Filter): boolean
	if filter.Kind ~= nil and event.Kind ~= filter.Kind then
		return false
	end
	if filter.Subject ~= nil and event.Subject ~= filter.Subject then
		return false
	end
	if filter.Where then
		for key, value in filter.Where do
			if event.Data[key] ~= value then
				return false
			end
		end
	end
	return true
end
-- Class
-- the last so many things the harness saw happen, each with a number to ask from. it's a ring: what's older than its
-- size is gone, + whoever reads is told the number it starts at
local Log = {} :: LogImpl
Log.__index = Log

function Log:GetLast(): number
	return self._Last
end

function Log:GetFirst(): number
	return math.max(self._Last - self._Capacity, 0) + 1
end

function Log:Add(kind: string, subject: string?, data: { [string]: any }?)
	self._Last += 1
	self._Events[self._Last] = table.freeze({
		Sequence = self._Last,
		Time = Workspace:GetServerTimeNow(),
		Kind = kind,
		Subject = subject,
		Data = Plain.from(data or {}),
	})
	self._Events[self._Last - self._Capacity] = nil
end

function Log:Read(since: number, filter: Filter): { Event }
	local out: { Event } = {}
	for sequence = math.max(since + 1, self:GetFirst()), self._Last do
		local event = self._Events[sequence]
		if event and getIfPassed(event, filter) then
			table.insert(out, event)
		end
	end
	return out
end

function Log:Wait(since: number, filter: Filter, timeout: number): Event?
	local deadline = os.clock() + timeout
	local from = since
	while true do
		local event = self:Read(from, filter)[1]
		if event then
			return event
		end
		-- nothing up to here passes, the next look starts after it
		from = math.max(from, self._Last)
		if os.clock() >= deadline then
			return nil
		end
		task.wait()
	end
end

return {
	new = function(capacity: number): Log
		assert(capacity >= 1 and capacity % 1 == 0, `a log keeps a whole number of events, received {capacity}`)
		return setmetatable({
			_Capacity = capacity,
			_Last = 0,
			_Events = {},
		}, Log)
	end,
}
