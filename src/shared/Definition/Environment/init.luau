--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
export type Season = EnvironmentType.Season
export type Weather = EnvironmentType.Weather
export type TimeOfDay = EnvironmentType.TimeOfDay
export type WeatherLook = EnvironmentType.WeatherLook
export type SeasonLook = EnvironmentType.SeasonLook
export type Climate = EnvironmentType.Climate
-- Constants
local HOURS_PER_DAY = 24
-- the weather of a game is its own, a game without any never requires this: its day is the day night service's
local CLIMATE: Climate = GameDefinition.pick({
	shl1 = function(): Climate
		error(`shl1 has no weather`)
	end,
	shl2 = function(): Climate
		error(`shl2 has no weather`)
	end,
	shl3 = function(): Climate
		return require("@self/SHL3")
	end,
})
assert(EnvironmentType.Climate(CLIMATE))
TableUtil.deepFreeze(CLIMATE)
-- Variables
-- References
-- Private Functions
-- Class
-- nothing in here keeps time: the server says when its clock started + both sides work the hour out from that
local Module = {}

-- a row that's left out is one the checker lets through. a season that's read out of a list is written down with
-- its type: the checker only knows one that isn't for a string
assert(#CLIMATE.Seasons > 0, `the year has no season`)
for _, season: Season in CLIMATE.Seasons do
	assert(CLIMATE.SeasonLooks[season], `the season "{season}" has no look`)
	local ticketCount = 0
	for _, odds in assert(CLIMATE.Odds[season], `the season "{season}" has no odds`) do
		assert(CLIMATE.WeatherLooks[odds.Weather], `the weather "{odds.Weather}" has no look`)
		ticketCount += odds.Tickets
	end
	assert(ticketCount > 0, `the season "{season}" has no weather to roll`)
end
assert(CLIMATE.WeatherLooks[CLIMATE.StartWeather], `the weather "{CLIMATE.StartWeather}" has no look`)
assert(#CLIMATE.Spouts > 0 and #CLIMATE.Spouts % 2 == 0, `a spout runs + is dry in turns, the two come in pairs`)

Module.CLIMATE = CLIMATE
-- seconds
Module.DAY_DURATION = HOURS_PER_DAY * CLIMATE.HourDuration

-- seconds from the start of the clock until it reads that hour for the first time
Module.getHourAt = function(hour: number): number
	return ((hour - CLIMATE.StartHour) % HOURS_PER_DAY) * CLIMATE.HourDuration
end

-- in hours on the clock of the lighting, from when the clock of the server started + what time the server has now
Module.getClockTime = function(startedAt: number, now: number): number
	return (CLIMATE.StartHour + (now - startedAt) / CLIMATE.HourDuration) % HOURS_PER_DAY
end

Module.getIfNight = function(clockTime: number): boolean
	return clockTime >= CLIMATE.Dusk or clockTime < CLIMATE.Dawn
end

-- the hour a sky that's held at a time of day shows
Module.getHour = function(timeOfDay: TimeOfDay): number
	return CLIMATE.TimeHours[timeOfDay]
end

-- if the spouts of the map run right now, + for how many seconds that stays so. they all started with the clock,
-- so every one of them is in step on every client
Module.getIfSpouting = function(startedAt: number, now: number): (boolean, number)
	local cycleDuration = 0
	for _, duration in CLIMATE.Spouts do
		cycleDuration += duration
	end
	local elapsed = (now - startedAt) % cycleDuration
	local isSpouting = true
	for _, duration in CLIMATE.Spouts do
		if elapsed < duration then
			return isSpouting, duration - elapsed
		end
		elapsed -= duration
		isSpouting = not isSpouting
	end
	-- a rounding that fell off the end of the last stretch is the start of the first
	return true, CLIMATE.Spouts[1]
end

-- every weather has as many tickets as its season gives it, one is drawn
Module.rollWeather = function(season: Season, rng: Random): Weather
	local ticketCount = 0
	for _, odds in CLIMATE.Odds[season] do
		ticketCount += odds.Tickets
	end
	local ticket = rng:NextInteger(1, ticketCount)
	for _, odds in CLIMATE.Odds[season] do
		if ticket <= odds.Tickets then
			return odds.Weather
		end
		ticket -= odds.Tickets
	end
	error(`no weather of the "{season}" has ticket {ticket}`)
end

Module.getWeatherLook = function(weather: Weather): WeatherLook
	return CLIMATE.WeatherLooks[weather]
end

Module.getSeasonLook = function(season: Season): SeasonLook
	return CLIMATE.SeasonLooks[season]
end

return Module
