--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
export type LampLook = {
	Material: Enum.Material,
	Transparency: number,
	BrickColor: BrickColor,
}
-- a time on the clock, the way it's read
export type ClockTime = {
	Hour: number,
	Minute: number,
}
-- how bright the sky is by the hour, in hours on the clock of the lighting
export type Sky = {
	SunriseTime: number,
	SunsetTime: number,
	TwilightDuration: number,
	DayBrightness: number,
	NightBrightness: number,
}
-- the day of a game: every game that has one runs on the same hands, what hours it keeps + what changes with them is
-- its own
export type Clock = {
	-- what the clock reads as a server starts
	Start: ClockTime,
	-- when the street lights + the windows switch
	Dawn: ClockTime,
	Dusk: ClockTime,
	-- seconds a tick takes by day
	TickDuration: number,
	-- how many times faster the night goes by
	NightSpeed: number,
	-- without one the sky stays as bright as the lighting of the map has it
	Sky: Sky?,
	-- without them a street light is left the way the map has it
	LampLooks: { Lit: LampLook, Unlit: LampLook }?,
	-- seconds a building takes to get all of its windows lit or dark, a room at a time. at 0 they switch at once
	WindowSwitchDuration: number,
	-- how much of the room behind it a lit window lets through, in tenths. a dark one is taken out of sight altogether
	LitWindowTenths: { Min: number, Max: number },
}
-- Constants
local MINUTES_PER_HOUR = 60
-- the minute hand runs from 0 up to + including 60 before the hour turns, so the top of every hour lasts for two ticks
local TICKS_PER_HOUR = MINUTES_PER_HOUR + 1
local TICKS_PER_DAY = 24 * TICKS_PER_HOUR
local isClockTime = Type.strictInterface({
	Hour = Type.intersection(Type.integer, Type.numberConstrained(0, 23)),
	Minute = Type.intersection(Type.integer, Type.numberConstrained(0, MINUTES_PER_HOUR)),
})
local isLampLook = Type.strictInterface({
	Material = Type.enum(Enum.Material),
	Transparency = Type.numberConstrained(0, 1),
	BrickColor = Type.BrickColor,
})
local isClock = Type.strictInterface({
	Start = isClockTime,
	Dawn = isClockTime,
	Dusk = isClockTime,
	TickDuration = Type.numberPositive,
	NightSpeed = Type.numberPositive,
	Sky = Type.optional(Type.strictInterface({
		SunriseTime = Type.numberConstrained(0, 24),
		SunsetTime = Type.numberConstrained(0, 24),
		TwilightDuration = Type.numberMin(0),
		DayBrightness = Type.numberMin(0),
		NightBrightness = Type.numberMin(0),
	})),
	LampLooks = Type.optional(Type.strictInterface({
		Lit = isLampLook,
		Unlit = isLampLook,
	})),
	WindowSwitchDuration = Type.numberMin(0),
	LitWindowTenths = Type.strictInterface({
		Min = Type.intersection(Type.integer, Type.numberConstrained(0, 10)),
		Max = Type.intersection(Type.integer, Type.numberConstrained(0, 10)),
	}),
})
-- the hours of a game are its own, the clock of another game is never required
local CLOCK: Clock = GameDefinition.pick({
	shl1 = function(): Clock
		return require("@self/SHL1")
	end,
	shl2 = function(): Clock
		return require("@self/SHL2")
	end,
	shl3 = function(): Clock
		error(`shl3 has no clock yet`)
	end,
})
assert(isClock(CLOCK))
TableUtil.deepFreeze(CLOCK)
local SKY = CLOCK.Sky
-- Variables
-- References
-- Private Functions
local function toTick(clockTime: ClockTime): number
	return clockTime.Hour * TICKS_PER_HOUR + clockTime.Minute
end
-- Class
local Module = {}

local DAWN_TICK = toTick(CLOCK.Dawn)
local DUSK_TICK = toTick(CLOCK.Dusk)

Module.START_TICK = toTick(CLOCK.Start)
-- nil in a game whose street lights are left the way its map has them
Module.LAMP_LOOKS = CLOCK.LampLooks
-- seconds a building takes to get all of its windows lit or dark, a room at a time. at 0 they switch at once
Module.WINDOW_SWITCH_DURATION = CLOCK.WindowSwitchDuration
-- how much of the room behind it a lit window lets through, in tenths. a dark one is taken out of sight altogether
Module.LIT_WINDOW_TENTHS = NumberRange.new(CLOCK.LitWindowTenths.Min, CLOCK.LitWindowTenths.Max)

Module.getNextTick = function(clockTick: number): number
	return (clockTick + 1) % TICKS_PER_DAY
end

-- in hours on the clock of the lighting
Module.getClockTime = function(clockTick: number): number
	return clockTick // TICKS_PER_HOUR + (clockTick % TICKS_PER_HOUR) / MINUTES_PER_HOUR
end

Module.getIfNight = function(clockTick: number): boolean
	return clockTick >= DUSK_TICK or clockTick < DAWN_TICK
end

-- the sky isn't eased in or out. over dawn it climbs from black to less than a third of the day's + then jumps the
-- rest, over dusk it gives up a tenth before it drops to the night's. on the stroke of the hour the day's
-- brightness starts or ends at there's nothing to set, it stays what it was. nor is there in a game whose sky stays
-- the way its map has it
Module.getBrightness = function(clockTime: number): number?
	if not SKY then
		return nil
	end
	local dayStartTime = SKY.SunriseTime + SKY.TwilightDuration
	local nightStartTime = SKY.SunsetTime + SKY.TwilightDuration
	if clockTime < SKY.SunriseTime or clockTime > nightStartTime then
		return SKY.NightBrightness
	elseif clockTime > dayStartTime and clockTime < SKY.SunsetTime then
		return SKY.DayBrightness
	elseif clockTime < dayStartTime then
		return SKY.DayBrightness * (clockTime - SKY.SunriseTime) / dayStartTime
	elseif clockTime > SKY.SunsetTime then
		return SKY.DayBrightness - SKY.DayBrightness * (clockTime - SKY.SunsetTime) / nightStartTime
	end
	return nil
end

Module.getTickDuration = function(isNight: boolean): number
	return if isNight then CLOCK.TickDuration / CLOCK.NightSpeed else CLOCK.TickDuration
end

return Module
