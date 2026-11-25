--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
-- which way whoever arrives looks: the way the exit does, or at the line straight up through the middle of the map
export type Facing = "Exit" | "Center"
-- the pads of a game: whoever steps on one stands at the exit of the same id. a pair leads one way
export type Rule = {
	-- seconds a pad carries nobody for once it carried somebody
	PadCooldown: number,
	-- seconds whoever just arrived is carried by no pad
	ArrivalImmunity: number,
	-- whole studs over the middle of the exit they're set down at, any of them from the first to the last
	Rise: { Min: number, Max: number },
	-- whole studs off to either side they may be set down, along both of the level axes
	Spread: number,
	Facing: Facing,
	-- a pad that leads nowhere stops the server, where it doesn't the pad is told of + carries nobody
	IsExitRequired: boolean,
}
-- Constants
local isRule = Type.strictInterface({
	PadCooldown = Type.numberMin(0),
	ArrivalImmunity = Type.numberMin(0),
	Rise = Type.strictInterface({
		Min = Type.integer,
		Max = Type.integer,
	}),
	Spread = Type.intersection(Type.integer, Type.numberMin(0)),
	Facing = Type.literal("Exit", "Center"),
	IsExitRequired = Type.boolean,
})
-- the pads of a game are its own, the rule of another game is never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		return require("@self/SHL1")
	end,
	shl2 = function(): Rule
		error(`shl2 has no pads`)
	end,
	shl3 = function(): Rule
		return require("@self/SHL3")
	end,
})
assert(isRule(RULE))
assert(RULE.Rise.Min <= RULE.Rise.Max, `the pads rise {RULE.Rise.Min} to {RULE.Rise.Max} studs`)
TableUtil.deepFreeze(RULE)
-- Variables
-- References
-- Private Functions
-- Class
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	PAD_COOLDOWN = RULE.PadCooldown,
	ARRIVAL_IMMUNITY = RULE.ArrivalImmunity,
	RISE = RULE.Rise,
	SPREAD = RULE.Spread,
	FACING = RULE.Facing,
	IS_EXIT_REQUIRED = RULE.IsExitRequired,
}

return Module
