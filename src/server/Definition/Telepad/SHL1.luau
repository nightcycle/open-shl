--!strict
-- Services
-- Packages
-- Modules
-- Types
-- the definition asks for this file, so the type is spelt out here
type Facing = "Exit" | "Center"
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- whoever touches a pad stands 2 or 3 studs over its landing, up to a stud off to any side, turned to the middle of
-- the map. its old place shut the pad to everybody for 3 seconds: a touch is the client's to send, so one of them
-- could have kept an elevator shut for good. the 3 seconds are the rider's own here, nobody else waits. one of its
-- pads never had a landing + did nothing
return table.freeze({
	PadCooldown = 0,
	ArrivalImmunity = 3,
	Rise = table.freeze({ Min = 2, Max = 3 }),
	Spread = 1,
	Facing = "Center" :: Facing,
	IsExitRequired = false,
})
