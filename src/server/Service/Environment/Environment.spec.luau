--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
-- only a game with weather has anything to hold this to, + its climate raises as it's read in any other
if not GameDefinition.FEATURES.Environment then
	return {} :: TestMap
end
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local ScheduleUtil = require("@game/ServerScriptService/Server/Service/Environment/Schedule")
type Season = EnvironmentDefinition.Season
type Weather = EnvironmentDefinition.Weather
-- Constants
local CLIMATE = EnvironmentDefinition.CLIMATE
local DAY_DURATION = EnvironmentDefinition.DAY_DURATION
-- a server that's been up for a while, so nothing passes by starting at 0
local STARTED_AT = 1234.5
local SIMULATED_DAYS = 40
-- Variables
-- References
-- Private Functions
-- a draw that isn't one: it hands out the ticket it's told to, whatever the bounds
local function newRandom(getTicket: (min: number, max: number) -> number): Random
	local rng = {}
	function rng.NextInteger(_self: unknown, min: number, max: number): number
		return getTicket(min, max)
	end
	return (rng :: any) :: Random
end

local function getTicketCount(season: Season): number
	local count = 0
	for _, odds in CLIMATE.Odds[season] do
		count += odds.Tickets
	end
	return count
end

-- the weather the last ticket of a season is
local function getLastWeather(season: Season): Weather
	local weather: Weather? = nil
	for _, odds in CLIMATE.Odds[season] do
		if odds.Tickets > 0 then
			weather = odds.Weather
		end
	end
	assert(weather, `the "{season}" has no ticket`)
	return weather
end
-- Class
local Tests: TestMap = {
	-- the hour is worked out from when the clock started: it starts where the game says, gets to dawn + dusk on time
	-- + comes round again after a day
	Clock = SpecUtil.newScenario(function()
		local function getAt(seconds: number): number
			return EnvironmentDefinition.getClockTime(STARTED_AT, STARTED_AT + seconds)
		end
		assert(getAt(0) == CLIMATE.StartHour, `the clock starts at {getAt(0)}`)
		assert(getAt(CLIMATE.HourDuration) == (CLIMATE.StartHour + 1) % 24, `an hour in it reads {getAt(20)}`)
		local dawnAt = EnvironmentDefinition.getHourAt(CLIMATE.Dawn)
		local duskAt = EnvironmentDefinition.getHourAt(CLIMATE.Dusk)
		assert(getAt(dawnAt) == CLIMATE.Dawn, `at dawn it reads {getAt(dawnAt)}`)
		assert(getAt(duskAt) == CLIMATE.Dusk, `at dusk it reads {getAt(duskAt)}`)
		assert(getAt(DAY_DURATION) == CLIMATE.StartHour, `a day in it reads {getAt(DAY_DURATION)}`)
		assert(getAt(3 * DAY_DURATION + dawnAt) == CLIMATE.Dawn, `the fourth dawn reads something else`)
		for _, hour in { 0, 6.99, 23.99 } do
			assert(getAt(EnvironmentDefinition.getHourAt(hour)) < 24, `the clock reads 24 or more`)
		end

		assert(EnvironmentDefinition.getIfNight(CLIMATE.Dawn - 0.01), `it's day before dawn`)
		assert(not EnvironmentDefinition.getIfNight(CLIMATE.Dawn), `it's night at dawn`)
		assert(not EnvironmentDefinition.getIfNight(CLIMATE.Dusk - 0.01), `it's night before dusk`)
		assert(EnvironmentDefinition.getIfNight(CLIMATE.Dusk), `it's day at dusk`)
		-- the old place: an hour of 20 seconds, the windows go dark 140 seconds in + light up at 360
		if GameDefinition.ID == "shl3" then
			assert(DAY_DURATION == 480, `a day takes {DAY_DURATION} seconds`)
			assert(dawnAt == 140 and duskAt == 360, `dawn is {dawnAt} seconds in + dusk {duskAt}`)
			assert(getAt(140) == 7 and getAt(360) == 18 and getAt(480) == 0, `the hours of the old place are off`)
			assert(EnvironmentDefinition.getIfNight(getAt(0)), `a server starts by day`)
		end
	end),

	-- a spout runs + is dry in turns, from the start of the clock + over again once the list is through
	Spouts = SpecUtil.newScenario(function()
		local function getAt(seconds: number): (boolean, number)
			return EnvironmentDefinition.getIfSpouting(STARTED_AT, STARTED_AT + seconds)
		end
		local startsAt = 0
		local cycleDuration = 0
		for _, duration in CLIMATE.Spouts do
			cycleDuration += duration
		end
		for index, duration in CLIMATE.Spouts do
			local isRunning = index % 2 == 1
			for _, cycle in { 0, 1, 7 } do
				local at = cycle * cycleDuration + startsAt
				local isSpouting, remaining = getAt(at)
				assert(isSpouting == isRunning, `stretch {index} starts as {isSpouting}`)
				assert(
					math.abs(remaining - duration) < 1e-6,
					`stretch {index} has {remaining} seconds left as it starts`
				)
				isSpouting, remaining = getAt(at + duration - 0.1)
				assert(isSpouting == isRunning, `stretch {index} ends early`)
				assert(math.abs(remaining - 0.1) < 1e-6, `stretch {index} has {remaining} seconds left as it ends`)
			end
			startsAt += duration
		end
		if GameDefinition.ID == "shl3" then
			local expected =
				{ [0] = true, [13.9] = true, [14] = false, [23] = true, [26.9] = true, [27] = false, [38] = true }
			for at, isRunning in expected do
				assert(getAt(at) == isRunning, `{at} seconds in a spout of the old place is {not isRunning}`)
			end
		end
	end),

	-- every ticket of a season is one weather's + a weather gets as many draws as it has tickets
	Lottery = SpecUtil.newScenario(function()
		for _, season: Season in CLIMATE.Seasons do
			local ticketCount = getTicketCount(season)
			local counts: { [Weather]: number } = {}
			for ticket = 1, ticketCount do
				local weather: Weather = EnvironmentDefinition.rollWeather(
					season,
					newRandom(function(min: number, max: number): number
						assert(min == 1 and max == ticketCount, `the "{season}" is drawn from {min} to {max}`)
						return ticket
					end)
				)
				counts[weather] = (counts[weather] or 0) + 1
			end
			for _, odds in CLIMATE.Odds[season] do
				local count = counts[odds.Weather] or 0
				assert(count == odds.Tickets, `"{odds.Weather}" is drawn {count} times in the "{season}"`)
				counts[odds.Weather] = nil
			end
			assert(next(counts) == nil, `the "{season}" draws a weather it has no ticket for`)
		end
		if GameDefinition.ID == "shl3" then
			assert(getTicketCount("summer") == 38 and getTicketCount("autumn") == 23, `the tickets are off`)
			assert(getTicketCount("winter") == 45 and getTicketCount("spring") == 38, `the tickets are off`)
		end
	end),

	-- one roll on the first day + one a day after it, a season is over with the last of its rolls + the roll that
	-- follows is drawn from the next one's tickets
	Schedule = SpecUtil.newScenario(function()
		-- the last ticket every time, which is another weather in every season
		local rng = newRandom(function(_min: number, max: number): number
			return max
		end)
		local state = ScheduleUtil.new()
		assert(state.Season == CLIMATE.Seasons[1] and state.SeasonsPassed == 0, `a year starts mid way`)
		assert(state.Weather == CLIMATE.StartWeather, `a server starts under "{state.Weather}"`)
		assert(
			ScheduleUtil.getRollAt(1) == EnvironmentDefinition.getHourAt(CLIMATE.FirstRollHour),
			`the first roll is {ScheduleUtil.getRollAt(1)} seconds in`
		)
		local rollAt = EnvironmentDefinition.getHourAt(CLIMATE.RollHour)
		assert(ScheduleUtil.getRollAt(1) ~= rollAt, `the first day is rolled when every other is`)
		for rollNumber = 1, SIMULATED_DAYS do
			local nextState = ScheduleUtil.step(state, rollNumber, rng)
			assert(table.isfrozen(nextState), `the year after roll {rollNumber} isn't frozen`)
			local seasonsPassed = (rollNumber - 1) // CLIMATE.RollsPerSeason
			assert(
				nextState.SeasonsPassed == seasonsPassed,
				`{nextState.SeasonsPassed} seasons are over after roll {rollNumber}`
			)
			local season: Season = CLIMATE.Seasons[seasonsPassed % #CLIMATE.Seasons + 1]
			assert(nextState.Season == season, `roll {rollNumber} is in the "{nextState.Season}"`)
			assert(
				nextState.Weather == getLastWeather(season),
				`roll {rollNumber} drew "{nextState.Weather}", which isn't the last ticket of the "{season}"`
			)
			if rollNumber > 1 then
				-- day n is rolled at its hour, + never twice
				assert(
					ScheduleUtil.getRollAt(rollNumber) == (rollNumber - 1) * DAY_DURATION + rollAt,
					`roll {rollNumber} is {ScheduleUtil.getRollAt(rollNumber)} seconds in`
				)
			end
			state = nextState
		end
		-- the old place: 20 seconds in, then at 13:00 of the day after, the autumn 1,700 seconds in + a season every
		-- 24 minutes from there
		if GameDefinition.ID == "shl3" then
			assert(ScheduleUtil.getRollAt(1) == 20 and ScheduleUtil.getRollAt(2) == 740, `the first rolls are off`)
			assert(ScheduleUtil.getRollAt(4) == 1700 and ScheduleUtil.getRollAt(7) == 3140, `the seasons are off`)
			local year = ScheduleUtil.new()
			local seasons: { Season } = {}
			for rollNumber = 1, 13 do
				year = ScheduleUtil.step(year, rollNumber, rng)
				seasons[rollNumber] = year.Season
			end
			assert(seasons[3] == "summer" and seasons[4] == "autumn", `the autumn doesn't start with roll 4`)
			assert(seasons[7] == "winter" and seasons[10] == "spring", `winter + spring aren't rolls 7 + 10`)
			assert(seasons[13] == "summer" and year.SeasonsPassed == 4, `the year isn't round after 12 rolls`)
		end
	end),
}

return Tests
