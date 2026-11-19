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
-- a server starts at five in the afternoon, a day is 609 seconds + the night goes by no faster. the windows of every
-- tower come on at a quarter past six + go off at a quarter past six, all at once + all as bright. nothing else
-- changes with the hour: the sky stays as bright as the map has it, + the street lights are on day + night
return table.freeze({
	Start = table.freeze({ Hour = 17, Minute = 0 }),
	Dawn = table.freeze({ Hour = 6, Minute = 15 }),
	Dusk = table.freeze({ Hour = 18, Minute = 15 }),
	TickDuration = 0.416,
	NightSpeed = 1,
	Sky = nil,
	LampLooks = nil,
	WindowSwitchDuration = 0,
	LitWindowTenths = table.freeze({ Min = 3, Max = 3 }),
})
