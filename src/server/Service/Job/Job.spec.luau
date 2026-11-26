--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ShiftUtil = require("@game/ServerScriptService/Server/Service/Job/Shift")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local JobType = require("@game/ServerScriptService/Server/Type/Job")
local SharedJobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type Card = JobType.Card
type JobId = SharedJobType.JobId
type Rule = JobType.Rule
type Shift = JobType.Shift
type Stat = SharedJobType.Stat
type TestMap = SimpleTest.TestMap
-- Constants
-- what a shift of the old place had earned after that many answers, counted by hand off its client
local PAYCHECKS: { [number]: number } = table.freeze({
	[1] = 25,
	[2] = 51,
	[3] = 77,
	[4] = 104,
	[5] = 131,
	[10] = 275,
	[17] = 497,
	[20] = 600,
	[30] = 975,
	[38] = 1310,
	[50] = 1826,
	[100] = 3976,
})
-- how many cards the file of the old place has for each, the last are the ones every job asks
local CARD_COUNTS = table.freeze({ Teacher = 19, Doctor = 11, Mentor = 19, Businessperson = 21, Misc = 22 })
local JOB_IDS: { JobId } =
	table.freeze({ "Teacher" :: JobId, "Doctor" :: JobId, "Mentor" :: JobId, "Businessperson" :: JobId })
local STATS: { Stat } =
	table.freeze({ "Morality" :: Stat, "Colleagues" :: Stat, "Accomplishments" :: Stat, "Happiness" :: Stat })
-- the same shifts every run
local SEED = 20_190_217
-- Variables
-- References
-- Private Functions
-- only read where the game has jobs: the definition of one without them raises
local function getDefinition()
	return require("@game/ServerScriptService/Server/Definition/Job")
end

-- a card that moves one of the four + leaves the rest
local function newCard(stat: Stat, change: number): Card
	local card: Card = {
		Text = `{stat} {change}`,
		Morality = 0,
		Colleagues = 0,
		Accomplishments = 0,
		Happiness = 0,
	}
	card[stat] = change
	return table.freeze(card)
end

-- a shift that asks the card, with one of the four where it's put
local function newShift(rule: Rule, card: Card, stat: Stat?, value: number?): Shift
	local shift = table.clone(ShiftUtil.new(rule, "Teacher", { card }, Random.new(SEED)))
	if stat and value then
		shift[stat] = value
	end
	return table.freeze(shift)
end
-- Class
local Tests: TestMap = {
	-- the cheque of the old place answer for answer: a fortieth of the base more for each, up to seven fourths of it
	Pay = SpecUtil.newScenario(function()
		local rule = getDefinition().RULE
		local paycheck = 0
		for answerCount = 1, 100 do
			paycheck = ShiftUtil.getPay(rule, paycheck, answerCount)
			local expected = PAYCHECKS[answerCount]
			assert(
				expected == nil or paycheck == expected,
				`{answerCount} answers paid {paycheck}, the old place {expected}`
			)
		end
		-- the raise by itself, on a base it's read off without a remainder
		local wide = table.clone(rule)
		wide.BasePay = 100
		assert(ShiftUtil.getPay(wide, 0, 1) == 102, `the first answer pays {ShiftUtil.getPay(wide, 0, 1)} of 100`)
		assert(ShiftUtil.getPay(wide, 0, 37) == 174, `the 37th answer pays {ShiftUtil.getPay(wide, 0, 37)} of 100`)
		assert(ShiftUtil.getPay(wide, 0, 38) == 175, `the 38th answer pays {ShiftUtil.getPay(wide, 0, 38)} of 100`)
		assert(ShiftUtil.getPay(wide, 0, 1000) == 175, `the raise isn't capped`)
		-- a shift pays what its answers did, each on top of the last
		local card = newCard("Morality", 0)
		local shift = newShift(rule, card)
		local random = Random.new(SEED)
		for answerCount = 1, 5 do
			shift = ShiftUtil.answer(rule, shift, answerCount % 2 == 0, { card }, random, answerCount)
			assert(shift.AnswerCount == answerCount, `{answerCount} answers were counted as {shift.AnswerCount}`)
		end
		assert(shift.Paycheck == PAYCHECKS[5], `five answers of a shift paid {shift.Paycheck}`)
	end),

	-- each of the eight ways out, from one step short of it
	End = SpecUtil.newScenario(function()
		local rule = getDefinition().RULE
		local random = Random.new(SEED)
		assert(#rule.Ends == 2 * #STATS, `{#rule.Ends} ends for {#STATS} things a shift is judged by`)
		for _, jobEnd in rule.Ends do
			-- the checker takes what a loop hands out for any text at all
			local stat: Stat, isHigh = jobEnd.Stat, jobEnd.IsHigh
			local card = newCard(stat, 1)
			local shift = newShift(rule, card, stat, if isHigh then rule.MaxStat - 1 else 1)
			assert(ShiftUtil.getEnd(rule, shift) == nil, `a shift is over one short of the {stat} end`)
			-- a no takes off what a yes adds
			local away = ShiftUtil.answer(rule, shift, not isHigh, { card }, random, 0)
			assert(away.EndText == nil, `a step away from the {stat} end is the end`)
			local over = ShiftUtil.answer(rule, shift, isHigh, { card }, random, 0)
			assert(over.EndText == jobEnd.Text .. rule.EndSuffix, `{stat} at {over[stat]} reads "{over.EndText}"`)
			-- the answer that ended it is paid like any other
			assert(over.Paycheck == PAYCHECKS[1], `the last answer paid {over.Paycheck}`)
			local shown = ShiftUtil.getShown(over, 0)
			assert(shown.IsOver and shown.Text == over.EndText, `a shift that's over shows "{shown.Text}"`)
			assert(SharedJobType.JobShift(shown))
		end
		-- a card moves a meter by two at most, so one may step past its end: it's never kept there
		local past = ShiftUtil.answer(rule, newShift(rule, newCard("Happiness", 2), "Happiness", 1), false, {
			newCard("Happiness", 2),
		}, random, 0)
		assert(past.Happiness == 0, `happiness is kept at {past.Happiness}`)
		assert(SharedJobType.JobShift(ShiftUtil.getShown(past, 0)))
		-- two out at once read the first the old place asked about
		local both = table.clone(newShift(rule, newCard("Morality", 0)))
		both.Happiness = 0
		both.Colleagues = rule.MaxStat
		assert(
			ShiftUtil.getEnd(rule, both) == rule.Ends[4].Text .. rule.EndSuffix,
			`two ends at once read "{ShiftUtil.getEnd(rule, both)}"`
		)
		both.Morality = rule.MaxStat
		assert(
			ShiftUtil.getEnd(rule, both) == rule.Ends[2].Text .. rule.EndSuffix,
			`three ends at once read "{ShiftUtil.getEnd(rule, both)}"`
		)
	end),

	-- no card twice until all of them were up, then they start over
	Deck = SpecUtil.newScenario(function()
		local definition = getDefinition()
		local rule, decks = definition.RULE, definition.DECKS
		local total = 0
		for id, count in CARD_COUNTS :: { [string]: number } do
			local cards: { Card } = (decks :: { [string]: { Card } })[id]
			assert(#cards == count, `{id} has {#cards} cards, the old place {count}`)
			for index, card in cards do
				local success, msg = JobType.Card(card)
				assert(success, `card {index} of {id}: {msg}`)
			end
			total += #cards
		end
		assert(total == 92, `{total} cards`)
		local random = Random.new(SEED)
		for _, jobId: JobId in JOB_IDS do
			local cards = definition.getCards(jobId)
			local count = CARD_COUNTS[jobId] + CARD_COUNTS.Misc
			assert(#cards == count, `{jobId} asks {#cards} cards`)
			local shift = ShiftUtil.new(rule, jobId, cards, random)
			assert(SharedJobType.JobShift(ShiftUtil.getShown(shift, 0)))
			assert(shift.Morality == rule.StartStat and shift.Paycheck == 0, `{jobId} doesn't start at the start`)
			local last: Card? = nil
			for round = 1, 3 do
				local isAsked: { [Card]: true } = {}
				for index = 1, count do
					local card = shift.Card
					assert(table.find(cards, card), `{jobId} asks a card that isn't its own`)
					assert(not isAsked[card], `round {round} of {jobId} asks card {index} twice`)
					assert(card ~= last, `round {round} of {jobId} starts with the card the last ended on`)
					isAsked[card] = true
					last = nil
					if index < count then
						shift = ShiftUtil.draw(shift, cards, random)
					end
				end
				assert(#shift.Deck == 0, `{#shift.Deck} cards are left after all of {jobId} were up`)
				last = shift.Card
				shift = ShiftUtil.draw(shift, cards, random)
			end
		end
		-- a job with one card asks it over + over
		local card = newCard("Morality", 0)
		local only = ShiftUtil.draw(newShift(rule, card), { card }, random)
		assert(only.Card == card, `a deck of one card ran out`)
	end),

	-- the first card is answered whenever, every one after it once it was up for its time
	Pace = SpecUtil.newScenario(function()
		local rule = getDefinition().RULE
		local card = newCard("Morality", 0)
		local shift = newShift(rule, card)
		assert(ShiftUtil.getIfReady(rule, shift, 0), `the first card isn't answered right away`)
		local answeredAt = 100
		shift = ShiftUtil.answer(rule, shift, true, { card }, Random.new(SEED), answeredAt)
		assert(not ShiftUtil.getIfReady(rule, shift, answeredAt), `the second card is answered at once`)
		assert(
			not ShiftUtil.getIfReady(rule, shift, answeredAt + rule.ReadDuration - 0.01),
			`a card is answered before it was up for {rule.ReadDuration} seconds`
		)
		assert(
			ShiftUtil.getIfReady(rule, shift, answeredAt + rule.ReadDuration),
			`a card isn't answered once it was up for {rule.ReadDuration} seconds`
		)
	end),
}

-- only a game with jobs has anything to hold this to
return if GameDefinition.FEATURES.Jobs then Tests else {} :: TestMap
