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
-- whoever touches a pad stands right at its exit, turned the way the exit is: its old place set the root to the
-- part. no pad of it ever waited, + two of the rides up end a stud or two from the pad that leads back down, so a
-- wide body went straight back: whoever arrives is left alone for a second, which is new. a pad that's spelt wrong
-- mustn't pass for one that works
return table.freeze({
	PadCooldown = 0,
	ArrivalImmunity = 1,
	Rise = table.freeze({ Min = 0, Max = 0 }),
	Spread = 0,
	Facing = "Exit" :: Facing,
	IsExitRequired = true,
})
