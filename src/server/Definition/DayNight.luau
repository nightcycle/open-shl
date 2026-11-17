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
-- every time of day is in hours on the clock of the lighting
local START_TIME = 12
local DAWN_TIME = 6
local DUSK_TIME = 17.5
-- the sky starts to change before the street lights do + is done after them
local SUNRISE_TIME = 5
local SUNSET_TIME = 17
local TWILIGHT_DURATION = 2
local DAY_BRIGHTNESS = 3
local NIGHT_BRIGHTNESS = 1
-- seconds a minute on the clock takes by day, the night goes by faster
local MINUTE_DURATION = 0.416
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

Module.START_TIME = START_TIME
Module.LAMP_LOOKS = LAMP_LOOKS
-- seconds a building takes to get all of its windows lit or dark, a room at a time
Module.WINDOW_SWITCH_DURATION = 40
-- how much of the room behind it a lit window lets through, a dark one is taken out of sight altogether
Module.LIT_WINDOW_TRANSPARENCY = NumberRange.new(0.1, 0.6)

Module.getIfNight = function(clockTime: number): boolean
	return clockTime >= DUSK_TIME or clockTime < DAWN_TIME
end

Module.getBrightness = function(clockTime: number): number
	local sunrise = math.clamp((clockTime - SUNRISE_TIME) / TWILIGHT_DURATION, 0, 1)
	local sunset = math.clamp((clockTime - SUNSET_TIME) / TWILIGHT_DURATION, 0, 1)
	return NIGHT_BRIGHTNESS + (DAY_BRIGHTNESS - NIGHT_BRIGHTNESS) * (sunrise - sunset)
end

Module.getMinuteDuration = function(isNight: boolean): number
	return if isNight then MINUTE_DURATION / NIGHT_SPEED else MINUTE_DURATION
end

return Module
