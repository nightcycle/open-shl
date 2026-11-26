--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
-- how a beam of a grid is while it's lit or dark
export type Look = {
	Transparency: number,
	CanCollide: boolean,
}
-- a grid of beams that all go lit + dark together, each time for as long as is rolled then
export type Rule = {
	-- a phase lasts any whole number from Min to Max, over Divisor, in seconds
	Interval: { Min: number, Max: number, Divisor: number },
	Lit: Look,
	Dark: Look,
}
-- Constants
local isLook = Type.strictInterface({
	Transparency = Type.numberConstrained(0, 1),
	CanCollide = Type.boolean,
})
local isRule = Type.strictInterface({
	Interval = Type.strictInterface({
		Min = Type.intersection(Type.integer, Type.numberPositive),
		Max = Type.intersection(Type.integer, Type.numberPositive),
		Divisor = Type.numberPositive,
	}),
	Lit = isLook,
	Dark = isLook,
})
-- the grid under the museum of valor city, as its old place ran it: a phase of 1.5 to 4.5 seconds in tenths, lit or
-- dark alike, so one may be three times as long as the next. a lit beam is hardly seen + is a wall as well. one game
-- has grids, so there's no row of another to pick from
local RULE: Rule = {
	Interval = { Min = 15, Max = 45, Divisor = 10 },
	Lit = { Transparency = 0.9, CanCollide = true },
	Dark = { Transparency = 1, CanCollide = false },
}
assert(isRule(RULE))
assert(RULE.Interval.Min <= RULE.Interval.Max, `a phase lasts {RULE.Interval.Min} to {RULE.Interval.Max}`)
TableUtil.deepFreeze(RULE)
-- Variables
-- References
-- Private Functions
-- Class
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	INTERVAL = RULE.Interval,
	LIT = RULE.Lit,
	DARK = RULE.Dark,
}

-- seconds the phase that starts now lasts
Module.rollDuration = function(random: Random): number
	return random:NextInteger(RULE.Interval.Min, RULE.Interval.Max) / RULE.Interval.Divisor
end

return Module
