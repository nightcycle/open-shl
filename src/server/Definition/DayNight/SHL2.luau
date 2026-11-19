--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a server starts at noon. the street lights + the windows come on at half past five + go off at six, the night goes
-- by twice as fast as the day. the sky changes on its own schedule, + a building lights up a room at a time, each as
-- bright as it happens to be
return table.freeze({
	Start = table.freeze({ Hour = 12, Minute = 0 }),
	Dawn = table.freeze({ Hour = 6, Minute = 0 }),
	Dusk = table.freeze({ Hour = 17, Minute = 30 }),
	TickDuration = 0.416,
	NightSpeed = 2,
	Sky = table.freeze({
		SunriseTime = 5,
		SunsetTime = 17,
		TwilightDuration = 2,
		DayBrightness = 3,
		NightBrightness = 1,
	}),
	LampLooks = table.freeze({
		Lit = table.freeze({
			Material = Enum.Material.Neon,
			Transparency = 0,
			BrickColor = BrickColor.new("Bright orange"),
		}),
		Unlit = table.freeze({
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.7,
			BrickColor = BrickColor.new("Cool yellow"),
		}),
	}),
	WindowSwitchDuration = 40,
	LitWindowTenths = table.freeze({ Min = 1, Max = 6 }),
})
