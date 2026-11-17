--!strict
-- Services
-- Packages
-- Modules
-- Types
export type Phase = "Closed" | "Opening" | "Revealed" | "Leaving"
-- Constants
-- how long the doors take to slide apart + the camera to get inside of the vault
local OPEN_DURATION = 1.5
-- Variables
-- References
-- Private Functions
-- Class
return {
	OPEN_DURATION = OPEN_DURATION,
	-- how long each phase lasts before the next one starts by itself
	PHASE_DURATIONS = {
		Closed = 20,
		Opening = OPEN_DURATION,
		Revealed = 3.5,
		Leaving = 1,
	} :: { [Phase]: number },
	-- left out is the last one, the cut-scene is over after it
	NEXT_PHASES = {
		Closed = "Opening",
		Opening = "Revealed",
		Revealed = "Leaving",
	} :: { [Phase]: Phase? },
	-- how far each door slides out of the way, keyed by its name inside of the "Door" model of the vault
	DOOR_TRAVELS = {
		Door1 = Vector3.new(7.4, 0, 0),
		Door2 = Vector3.new(-7.4, 0, 0),
	} :: { [string]: Vector3 },
	-- the part of the vault the camera ends up at, it starts out at "Cam"
	OPEN_CAMERA_NAME = "Cam2",
}
