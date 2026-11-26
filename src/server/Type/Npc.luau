--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId

local Types = {}

-- how a walker feels its way: one ray ahead of it from its right shoulder, one higher up where that ran into
-- something, + one down where it ran into nothing. all of it in studs
export type Probe = {
	-- how far the rays ahead reach
	Length: number,
	-- where the ray ahead starts: that far to its right + that far under its middle
	Side: number,
	Drop: number,
	-- what the ray ahead leans to its left + rises by on the way, before it's cut to its length
	Lean: number,
	Rise: number,
	-- how much higher the second ray is: what it clears is jumped
	StepUp: number,
	-- the share of the length ahead at which the floor is asked for, + how far down it may be
	EdgeAhead: number,
	EdgeDepth: number,
	-- prey that's lower than this under it is walked off an edge for, + climbed after when it's this far over it
	Level: number,
	-- a walker that got less far than this since its last wake is stuck
	Stuck: number,
	-- how far ahead the goal of a detour is put
	Stride: number,
}
Types.Probe = Type.strictInterface({
	Length = Type.numberPositive,
	Side = Type.number,
	Drop = Type.number,
	Lean = Type.number,
	Rise = Type.number,
	StepUp = Type.numberPositive,
	EdgeAhead = Type.numberPositive,
	EdgeDepth = Type.numberPositive,
	Level = Type.numberMin(0),
	Stuck = Type.numberMin(0),
	Stride = Type.numberPositive,
})

-- one of the ways a walker stands about, the heavier the more often
export type Idle = {
	AnimationId: string,
	Weight: number,
}
Types.Idle = Type.strictInterface({
	AnimationId = Type.string,
	Weight = Type.numberPositive,
})

-- what the server plays on a walker. a pace is the speed an animation is at its own pace at
export type Animations = {
	Idles: { Idle },
	Walk: string,
	WalkPace: number,
	Jump: string,
	Fall: string,
	Climb: string,
	ClimbPace: number,
}
Types.Animations = Type.strictInterface({
	Idles = Type.array(Types.Idle),
	Walk = Type.string,
	WalkPace = Type.numberPositive,
	Jump = Type.string,
	Fall = Type.string,
	Climb = Type.string,
	ClimbPace = Type.numberPositive,
})

-- a picture of the library model the server points at the game's own upload as it clones it
export type Face = {
	Name: string, -- of the decal
	Image: string,
}
Types.Face = Type.strictInterface({
	Name = Type.string,
	Image = Type.string,
})

-- a kind of body nobody plays that walks the map by itself. its model is the one of the same id in the library
export type Npc = {
	Id: string,
	MaxHealth: number,
	WalkSpeed: number,
	-- studs it walks between two looks around: it wakes that often at its speed
	WakeDistance: number,
	-- seconds it stands about for once it's in, any time from the first to the last
	StartDelay: { Min: number, Max: number },
	-- studs it sees prey from
	Sight: number,
	-- the side it goes after. it hurts whoever it brushes
	PreyTeamId: TeamId,
	Probe: Probe,
	-- what a touch of its arms takes off + seconds until the next one does
	Damage: number,
	DamageCooldown: number,
	-- the parts whose name holds this hurt
	ArmPattern: string,
	-- the share of its health it gets back every so many seconds while it's hurt + up
	Regeneration: { Fraction: number, Interval: number },
	-- seconds it's left lying once it went down
	RemoveDelay: number,
	Animations: Animations,
	Face: Face?,
}
Types.Npc = Type.strictInterface({
	Id = Type.string,
	MaxHealth = Type.numberPositive,
	WalkSpeed = Type.numberPositive,
	WakeDistance = Type.numberPositive,
	StartDelay = Type.strictInterface({
		Min = Type.numberMin(0),
		Max = Type.numberMin(0),
	}),
	Sight = Type.numberPositive,
	PreyTeamId = CombatType.TeamId,
	Probe = Types.Probe,
	Damage = Type.numberMin(0),
	DamageCooldown = Type.numberMin(0),
	ArmPattern = Type.string,
	Regeneration = Type.strictInterface({
		Fraction = Type.numberConstrained(0, 1),
		Interval = Type.numberPositive,
	}),
	RemoveDelay = Type.numberMin(0),
	Animations = Types.Animations,
	Face = Type.optional(Types.Face),
})

return Types
