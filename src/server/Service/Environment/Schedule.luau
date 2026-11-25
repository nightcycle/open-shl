--!strict
-- Services
-- Packages
-- Modules
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
-- Types
type Season = EnvironmentDefinition.Season
type Weather = EnvironmentDefinition.Weather
-- what the year of a server has come to
export type State = {
	Season: Season,
	SeasonsPassed: number,
	Weather: Weather,
}
-- Constants
local CLIMATE = EnvironmentDefinition.CLIMATE
-- Variables
-- References
-- Private Functions
-- what a server starts with, before anything is rolled
local function new(): State
	local season: Season = CLIMATE.Seasons[1]
	return table.freeze({
		Season = season,
		SeasonsPassed = 0,
		Weather = CLIMATE.StartWeather,
	})
end

-- seconds from the start of the clock until the weather is rolled for the nth time. the first day is rolled early
-- + only once, every day after it at the same hour
local function getRollAt(rollNumber: number): number
	if rollNumber == 1 then
		return EnvironmentDefinition.getHourAt(CLIMATE.FirstRollHour)
	end
	return (rollNumber - 1) * EnvironmentDefinition.DAY_DURATION + EnvironmentDefinition.getHourAt(CLIMATE.RollHour)
end

-- the year after its nth roll. the roll that follows the last of a season is the first of the next one, + it's
-- drawn from the tickets of that one
local function step(state: State, rollNumber: number, rng: Random): State
	local seasonsPassed = state.SeasonsPassed
	if rollNumber > CLIMATE.RollsPerSeason and (rollNumber - 1) % CLIMATE.RollsPerSeason == 0 then
		seasonsPassed += 1
	end
	local season: Season = CLIMATE.Seasons[seasonsPassed % #CLIMATE.Seasons + 1]
	return table.freeze({
		Season = season,
		SeasonsPassed = seasonsPassed,
		Weather = EnvironmentDefinition.rollWeather(season, rng),
	})
end
-- Class
-- when the weather of a server is rolled + what its year comes to roll by roll: nothing in here waits or knows a
-- clock. every function is in from the start, one that's assigned afterwards the checker only knows for the widest
-- type it has
local Util = {
	new = new,
	getRollAt = getRollAt,
	step = step,
}

return Util
