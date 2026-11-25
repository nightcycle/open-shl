--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local TimerUtil = require("@game/ServerScriptService/Server/Service/Allowance/Timer")
-- Types
type TestMap = SimpleTest.TestMap
-- Constants
-- seconds between two beats, long enough for a server that's busy starting up to tell one from the next
local INTERVAL = 0.2
-- seconds a beat may be late by before the run gives up on it
local PATIENCE = 5
-- Variables
-- References
-- Private Functions
-- yields until that many beats were counted, false if they never came
local function await(getCount: () -> number, count: number): boolean
	local startTime = os.clock()
	while getCount() < count do
		if os.clock() - startTime > PATIENCE then
			return false
		end
		task.wait()
	end
	return true
end
-- Class
local Tests: TestMap = {
	-- one for every interval that went by, never one ahead of its time
	Pays = SpecUtil.newScenario(function()
		local count = 0
		local function getCount(): number
			return count
		end
		local startTime = os.clock()
		local thread = TimerUtil.start(INTERVAL, function()
			count += 1
		end)
		assert(count == 0, `it paid as it started`)
		local isPaid = await(getCount, 2)
		local duration = os.clock() - startTime
		TimerUtil.stop(thread)
		assert(isPaid, `it paid {count} times in {PATIENCE} seconds`)
		assert(duration >= INTERVAL * 2 - 0.02, `two were paid within {duration} seconds`)
	end),

	-- a beat that's stopped pays nothing more
	Stops = SpecUtil.newScenario(function()
		local count = 0
		local function getCount(): number
			return count
		end
		local thread = TimerUtil.start(INTERVAL, function()
			count += 1
		end)
		assert(await(getCount, 1), `it never paid`)
		TimerUtil.stop(thread)
		local paidCount = count
		task.wait(INTERVAL * 3)
		assert(count == paidCount, `it paid {count - paidCount} more once it was stopped`)
		-- stopping it twice is stopping it once
		TimerUtil.stop(thread)
	end),

	-- whoever comes back three times has one beat, counted from the last time: the old place had four by then
	Restarts = SpecUtil.newScenario(function()
		local count = 0
		local function getCount(): number
			return count
		end
		local function pay()
			count += 1
		end
		local thread = TimerUtil.start(INTERVAL, pay)
		for _ = 1, 3 do
			TimerUtil.stop(thread)
			thread = TimerUtil.start(INTERVAL, pay)
		end
		local startTime = os.clock()
		assert(count == 0, `it paid as it started`)
		local isPaid = await(getCount, 2)
		local duration = os.clock() - startTime
		TimerUtil.stop(thread)
		assert(isPaid, `it paid {count} times in {PATIENCE} seconds`)
		-- four beats would have paid two in the time one pays one
		assert(duration >= INTERVAL * 2 - 0.02, `two were paid within {duration} seconds: more than one beat runs`)
	end),
}

-- only a game that hands one out has anything to hold this to
return if GameDefinition.FEATURES.Allowance then Tests else {} :: TestMap
