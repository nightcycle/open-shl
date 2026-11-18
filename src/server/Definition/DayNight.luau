--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
export type LampLook = {
	Material: Enum.Material,
	Transparency: number,
	BrickColor: BrickColor,
}
-- Constants
local MINUTES_PER_HOUR = 60
-- the minute hand runs from 0 up to + including 60 before the hour turns, so the top of every hour lasts for two ticks
local TICKS_PER_HOUR = MINUTES_PER_HOUR + 1
local TICKS_PER_DAY = 24 * TICKS_PER_HOUR
local START_TICK = 12 * TICKS_PER_HOUR
-- when the street lights + the windows switch
local DAWN_TICK = 6 * TICKS_PER_HOUR
local DUSK_TICK = 17 * TICKS_PER_HOUR + 30
-- the sky changes on its own schedule, in hours on the clock of the lighting
local SUNRISE_TIME = 5
local SUNSET_TIME = 17
local TWILIGHT_DURATION = 2
local DAY_BRIGHTNESS = 3
local NIGHT_BRIGHTNESS = 1
-- seconds a tick takes by day, the night goes by faster
local TICK_DURATION = 0.416
local NIGHT_SPEED = 2
local LAMP_LOOKS: { Lit: LampLook, Unlit: LampLook } = {
	Lit = {
		Material = Enum.Material.Neon,
		Transparency = 0,
		BrickColor = BrickColor.new("Bright orange"),
	},
	Unlit = {
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.7,
		BrickColor = BrickColor.new("Cool yellow"),
	},
}
TableUtil.deepFreeze(LAMP_LOOKS)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.START_TICK = START_TICK
Module.LAMP_LOOKS = LAMP_LOOKS
-- seconds a building takes to get all of its windows lit or dark, a room at a time
Module.WINDOW_SWITCH_DURATION = 40
-- how much of the room behind it a lit window lets through, in tenths. a dark one is taken out of sight altogether
Module.LIT_WINDOW_TENTHS = NumberRange.new(1, 6)

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
-- brightness starts or ends at there's nothing to set, it stays what it was
Module.getBrightness = function(clockTime: number): number?
	local dayStartTime = SUNRISE_TIME + TWILIGHT_DURATION
	local nightStartTime = SUNSET_TIME + TWILIGHT_DURATION
	if clockTime < SUNRISE_TIME or clockTime > nightStartTime then
		return NIGHT_BRIGHTNESS
	elseif clockTime > dayStartTime and clockTime < SUNSET_TIME then
		return DAY_BRIGHTNESS
	elseif clockTime < dayStartTime then
		return DAY_BRIGHTNESS * (clockTime - SUNRISE_TIME) / dayStartTime
	elseif clockTime > SUNSET_TIME then
		return DAY_BRIGHTNESS - DAY_BRIGHTNESS * (clockTime - SUNSET_TIME) / nightStartTime
	end
	return nil
end

Module.getTickDuration = function(isNight: boolean): number
	return if isNight then TICK_DURATION / NIGHT_SPEED else TICK_DURATION
end

return Module
