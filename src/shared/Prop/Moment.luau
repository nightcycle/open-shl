--!strict
-- Services
-- Packages
-- Modules
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type StateMoment = PropType.StateMoment
type EventMoment = PropType.EventMoment
-- Constants
-- the whole time it's in the hand
local HOLD: StateMoment = table.freeze({ Kind = "State" :: "State", Name = "Hold" :: "Hold" })
-- in the hand + not being used. the same time as Hold for a prop that has no use
local REST: StateMoment = table.freeze({ Kind = "State" :: "State", Name = "Rest" :: "Rest" })
-- for as long as one use lasts
local USING: StateMoment = table.freeze({ Kind = "State" :: "State", Name = "Using" :: "Using" })
-- it came into the hand
local DRAW: EventMoment = table.freeze({ Kind = "Event" :: "Event", Name = "Draw" :: "Draw" })
-- a use starts
local USE: EventMoment = table.freeze({ Kind = "Event" :: "Event", Name = "Use" :: "Use" })
-- a use ran its full length. one that's cut short never gets here
local FINISH: EventMoment = table.freeze({ Kind = "Event" :: "Event", Name = "Finish" :: "Finish" })
-- Variables
-- References
-- Private Functions
-- Class
-- what a prop hangs its effects on, where an ability has the bindings of its layout. every prop has these six +
-- nothing sets them off but the hand + a click
return table.freeze({
	Hold = HOLD,
	Rest = REST,
	Using = USING,
	Draw = DRAW,
	Use = USE,
	Finish = FINISH,
})
