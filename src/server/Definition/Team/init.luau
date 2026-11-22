--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- one of the sides, the way the engine lists it
export type Side = {
	Id: TeamId,
	Name: string,
	BrickColorNumber: number,
}
-- the sides of a game + how its players get onto them. who hurts whom is the rule of its fights, which both ends of
-- a hit read: this is only the server's
export type Rule = {
	Sides: { Side },
	-- where somebody goes who comes in while neither side is ahead
	JoinTeamId: TeamId,
	-- nobody leaves for a side that's ahead of theirs by more than this
	MaxLead: number,
	-- what somebody who's kept on their side for it is told
	RefusalText: string,
}
-- Constants
local isRule = Type.intersection(
	Type.strictInterface({
		Sides = Type.array(Type.strictInterface({
			Id = CombatType.TeamId,
			Name = Type.string,
			BrickColorNumber = Type.intersection(Type.integer, Type.numberPositive),
		})),
		JoinTeamId = CombatType.TeamId,
		MaxLead = Type.intersection(Type.integer, Type.numberMin(0)),
		RefusalText = Type.string,
	}),
	-- whoever leaves a side goes to the other one, so there are the two of them + each once
	function(value: Rule): (boolean, string?)
		if #value.Sides ~= 2 or value.Sides[1].Id == value.Sides[2].Id then
			return false, `a game with sides has two of them`
		end
		return true
	end
)
-- the sides of a game are its own, the rule of another game is never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		error(`shl1 has no sides`)
	end,
	shl2 = function(): Rule
		error(`shl2 has no sides`)
	end,
	shl3 = function(): Rule
		return require("@self/SHL3")
	end,
})
assert(isRule(RULE))
TableUtil.deepFreeze(RULE)
-- Variables
-- References
-- Private Functions
-- Class
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	SIDES = RULE.Sides,
	JOIN_TEAM_ID = RULE.JoinTeamId,
	MAX_LEAD = RULE.MaxLead,
	REFUSAL_TEXT = RULE.RefusalText,
}

return Module
