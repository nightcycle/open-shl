--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local JobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type JobId = JobType.JobId
type Stat = JobType.Stat

local Types = {}

-- a question of a job the way the data file spells it: a yes adds the four numbers to the four a shift is judged by,
-- a no takes them off. the text is content of the old place, typos + all
export type Card = {
	Text: string,
	Morality: number,
	Colleagues: number,
	Accomplishments: number,
	Happiness: number,
}
do -- Types.Card
	-- the longest of the old place is 147 letters, the field of the screen holds a little more than that
	local MAX_TEXT_LENGTH = 200
	local function isText(value: unknown): (boolean, string?)
		if type(value) ~= "string" then
			return false, `string expected, got {typeof(value)}`
		end
		local length = utf8.len(value)
		if not length or length < 1 or length > MAX_TEXT_LENGTH then
			return false, `a text of 1 to {MAX_TEXT_LENGTH} letters expected, got {length or "one that's no utf8"}`
		end
		return true
	end
	local isChange = Type.intersection(Type.integer, Type.numberConstrained(-2, 2))
	Types.Card = Type.strictInterface({
		Text = isText,
		Morality = isChange,
		Colleagues = isChange,
		Accomplishments = isChange,
		Happiness = isChange,
	})
end

-- the cards of a game: the ones each job has to itself + the ones every job asks
export type Decks = {
	Teacher: { Card },
	Doctor: { Card },
	Mentor: { Card },
	Businessperson: { Card },
	Misc: { Card },
}
do -- Types.Decks
	local isCards = Type.intersection(Type.array(Types.Card), function(value: unknown): (boolean, string?)
		if next(value :: { unknown }) == nil then
			return false, `a deck without a card`
		end
		return true
	end)
	Types.Decks = Type.strictInterface({
		Teacher = isCards,
		Doctor = isCards,
		Mentor = isCards,
		Businessperson = isCards,
		Misc = isCards,
	})
end

-- a way a job ends: one of the four ran out or filled up
export type End = {
	Stat: Stat,
	IsHigh: boolean,
	-- what's read in place of a card from then on
	Text: string,
}
Types.End = Type.strictInterface({
	Stat = JobType.Stat,
	IsHigh = Type.boolean,
	Text = Type.string,
})

-- the numbers the jobs of a game run by
export type Rule = {
	-- what each of the four starts a shift at
	StartStat: number,
	-- a shift ends once one of the four is here or at 0
	MaxStat: number,
	-- what the first answer of a shift would pay at no raise
	BasePay: number,
	-- the share of the base pay every answer so far adds to the next
	RaisePerAnswer: number,
	-- the most an answer pays, as a multiple of the base pay
	MaxRaise: number,
	-- seconds a card is up for before it's answered
	ReadDuration: number,
	-- studs from its pad past which somebody isn't at their job any more
	Radius: number,
	-- seconds between two looks at who's still at a pad
	AuditInterval: number,
	-- the first that holds is the one that's read
	Ends: { End },
	-- what every end is followed by
	EndSuffix: string,
}
Types.Rule = Type.strictInterface({
	StartStat = Type.intersection(Type.integer, Type.numberPositive),
	MaxStat = Type.intersection(Type.integer, Type.numberPositive),
	BasePay = Type.numberMin(0),
	RaisePerAnswer = Type.numberMin(0),
	MaxRaise = Type.numberMin(1),
	ReadDuration = Type.numberMin(0),
	Radius = Type.numberPositive,
	AuditInterval = Type.numberPositive,
	Ends = Type.array(Types.End),
	EndSuffix = Type.string,
})

-- a shift the way the server keeps it: all of it is the server's, a client is told what it draws
export type Shift = {
	JobId: JobId,
	-- the one that's asked
	Card: Card,
	Morality: number,
	Colleagues: number,
	Accomplishments: number,
	Happiness: number,
	AnswerCount: number,
	Paycheck: number,
	-- when the last answer was taken, on whatever clock whoever answers reads. nil until the first
	AnsweredAt: number?,
	-- the line it ended on, nil while it's still on
	EndText: string?,
	-- what's left to ask before every card was + they're shuffled anew
	Deck: { Card },
}
Types.Shift = Type.strictInterface({
	JobId = JobType.JobId,
	Card = Types.Card,
	Morality = Type.integer,
	Colleagues = Type.integer,
	Accomplishments = Type.integer,
	Happiness = Type.integer,
	AnswerCount = Type.intersection(Type.integer, Type.numberMin(0)),
	Paycheck = Type.intersection(Type.integer, Type.numberMin(0)),
	AnsweredAt = Type.optional(Type.number),
	EndText = Type.optional(Type.string),
	Deck = Type.array(Types.Card),
})

return Types
