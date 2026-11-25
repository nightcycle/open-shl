--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
-- Types
local AcrobaticsType = require("@game/ReplicatedStorage/Shared/Type/Acrobatics")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Phase = AcrobaticsType.Phase
export type Move = AcrobaticsType.Move
-- Constants
-- every number in here is the old place's. it counted a move out in steps of its scheduler, which took thirty a second
local STEP = 1 / 30
-- a throw lasts a third as many steps as it starts out fast
local LIFT_DIVISOR = 3
-- + loses this much of its speed upwards with every one of them
local LIFT_DECAY = 4.25
-- the one button of the panel that's no move: it puts a body that was left lying back on its feet
local FIX_ID = "fix"
-- Variables
-- References
-- Private Functions
local function turn(count: number, x: number, y: number, z: number): Phase
	return {
		Type = "Turn" :: "Turn",
		Count = count,
		Angles = Vector3.new(x, y, z),
	}
end

local function pause(duration: number): Phase
	return {
		Type = "Pause" :: "Pause",
		Duration = duration,
	}
end

local function new(id: string, name: string, up: number, forward: number, phases: { Phase }): Move
	return {
		Id = id,
		Name = name,
		Up = up,
		Forward = forward,
		Phases = phases,
		IsTurned = true,
	}
end

-- in the order the old place listed them, which is the order of their buttons
local MOVES: { Move } = {
	new("360", "360", 45, 26, { turn(17, 0, math.pi / 9, 0) }),
	new("aerial", "Aerial", 35, 26, { turn(14, -math.pi / 7, -math.pi / 17, 0) }),
	new("360-pike", "360 Pike", 50, 26, {
		turn(5, -math.pi / 5, 0, 0),
		pause(STEP),
		turn(9, 0, math.pi / 4.5, 0),
		turn(5, -math.pi / 5, 0, 0),
	}),
	new("back-twist", "Back Twist", 50, -10, {
		turn(12, math.pi / 7, 0, 0),
		turn(9, 0, -math.pi / 4.5, 0),
		turn(2, math.pi / 7, 0, 0),
	}),
	new("back-flip", "Back Flip", 40, -26, { turn(14, math.pi / 7, 0, 0) }),
	new("dive", "Dive", 45, 30, {
		turn(3, -math.pi / 7, 0, 0),
		turn(6, -math.pi / 40, 0, 0),
		pause(0.2),
		turn(10, -math.pi / 7, 0, 0),
	}),
	-- the two rolls are thrown nowhere: the body turns over where it stands
	new("back-roll", "Back Roll", 0, 0, { turn(14, math.pi / 7, 0, 0) }),
	new("front-roll", "Front Roll", 0, 0, { turn(14, -math.pi / 7, -math.pi / 22, 0) }),
	new("front-flip", "Front Flip", 40, 26, { turn(14, -math.pi / 7, 0, 0) }),
	new("ktm", "KTM", 50, 1, {
		turn(4, math.pi / 6, 0, 0),
		pause(STEP),
		turn(16, math.pi / 14, 0, 0),
	}),
	new("gainer", "Gainer", 40, 26, { turn(14, math.pi / 7, 0, 0) }),
	new("lunge", "Lunge", 35, 50, { turn(14, -math.pi / 60, 0, 0) }),
	new("looser", "Looser", 40, -26, { turn(14, -math.pi / 7, 0, 0) }),
	new("planter-kick", "Planter Kick", 50, 26, {
		turn(8, -math.pi / 5, 0, 0),
		turn(14, -math.pi / 50, 0, 0),
	}),
	new("pike", "Pike", 45, 26, {
		turn(5, -math.pi / 5, 0, 0),
		pause(0.25),
		turn(5, -math.pi / 5, 0, 0),
	}),
	new("twister", "Twister", 50, 26, {
		turn(1, -math.pi / 3.5, 0, 0),
		turn(9, 0, math.pi / 4.5, 0),
		turn(10, -math.pi / 7, 0, 0),
	}),
	-- what was to turn it was made + never put on the body, so all it ever was is a jump: it's held for as long as
	-- its turn would have taken
	{
		Id = "spring",
		Name = "Spring",
		Up = 70,
		Forward = 8,
		Phases = { turn(14, -math.pi / 85, 0, 0) },
		IsTurned = false,
	},
}
local MovesById: { [string]: Move } = {}
for _, move in MOVES do
	assert(AcrobaticsType.Move(move))
	assert(move.Id ~= FIX_ID and MovesById[move.Id] == nil, `the "{move.Id}" move is listed twice`)
	MovesById[move.Id] = move
end
TableUtil.deepFreeze(MOVES)
-- the buttons of the panel as the old place numbered them, which is where each of them is put
local ORDER: { string } = {}
for index, move in MOVES do
	-- the way back up was its second
	if index == 2 then
		table.insert(ORDER, FIX_ID)
	end
	table.insert(ORDER, move.Id)
end
table.freeze(ORDER)
-- Class
local Module = {}

Module.STEP = STEP
Module.LIFT_DIVISOR = LIFT_DIVISOR
Module.LIFT_DECAY = LIFT_DECAY
Module.FIX_ID = FIX_ID
Module.MOVES = MOVES
Module.ORDER = ORDER

Module.get = function(id: string): Result<Move, string>
	local move = MovesById[id]
	if move then
		return Result.ok(move)
	end
	return Result.err(`no move "{id}"`)
end

return Module
