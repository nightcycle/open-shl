--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")

local Types = {}

-- no stretch of a move goes on for more steps than this
local MAX_COUNT = 64
-- seconds a body is held as it is at most
local MAX_PAUSE = 2
-- studs a second, nothing throws a body harder
local MAX_SPEED = 200

-- one stretch of a move: the body is turned a little further every step, or held the way it is for a while
export type Phase =
	{
		Type: "Turn",
		Count: number, -- steps
		Angles: Vector3, -- radians a step, about the axes of the body itself
	}
	| {
		Type: "Pause",
		Duration: number, -- seconds, it's over with the first step that's at least that late
	}
Types.Phase = Type.union(
	Type.strictInterface({
		Type = Type.literal("Turn"),
		Count = Type.intersection(Type.integer, Type.numberConstrained(1, MAX_COUNT)),
		Angles = AbilityType.FiniteVector3,
	}),
	Type.strictInterface({
		Type = Type.literal("Pause"),
		Duration = Type.numberConstrained(0, MAX_PAUSE),
	})
)

-- a flip or a roll: the body is thrown + turned over on its way
export type Move = {
	Id: string,
	Name: string, -- what its button reads
	Up: number, -- studs a second it's thrown straight up at
	Forward: number, -- studs a second along where the body looks as it starts, below 0 it's thrown backwards
	Phases: { Phase }, -- in order. a step of a turn + a step of the throw take as long as each other
	IsTurned: boolean, -- false: the body is only thrown, nothing turns it
}
Types.Move = Type.strictInterface({
	Id = Type.string,
	Name = Type.string,
	Up = Type.numberConstrained(0, MAX_SPEED),
	Forward = Type.numberConstrained(-MAX_SPEED, MAX_SPEED),
	Phases = Type.array(Types.Phase),
	IsTurned = Type.boolean,
})

return Types
