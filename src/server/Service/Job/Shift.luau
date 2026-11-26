--!strict
-- Services
-- Packages
-- Modules
-- Types
local JobType = require("@game/ServerScriptService/Server/Type/Job")
local SharedJobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type Card = JobType.Card
type JobId = SharedJobType.JobId
type JobShift = SharedJobType.JobShift
type Rule = JobType.Rule
type Shift = JobType.Shift
type Stat = SharedJobType.Stat
-- Constants
-- Variables
-- References
-- Private Functions
-- every card in an order of its own, the last of the list is the next that's asked
local function shuffle(cards: { Card }, random: Random): { Card }
	local deck = table.clone(cards)
	for index = #deck, 2, -1 do
		local other = random:NextInteger(1, index)
		deck[index], deck[other] = deck[other], deck[index]
	end
	return deck
end

-- a shift ends at either end, so none of the four is ever kept past one
local function move(rule: Rule, value: number, change: number): number
	return math.clamp(value + change, 0, rule.MaxStat)
end
-- Class
-- the part of a job that asks nothing of the engine: what's asked next, what an answer does + pays, when the next
-- one is taken + how a shift ends. a shift is never written to, each of these hands back the one that follows
local Util = {}

-- what an answer adds to the cheque, counted the way the old place did: on what was earned so far, rounded down
function Util.getPay(rule: Rule, paycheck: number, answerCount: number): number
	local raise = math.min(rule.MaxRaise, 1 + rule.RaisePerAnswer * answerCount)
	return math.floor(paycheck + rule.BasePay * raise)
end

-- the line a shift is over with, nil while none of the four is out at an end
function Util.getEnd(rule: Rule, shift: Shift): string?
	local stats: { [Stat]: number } = {
		Morality = shift.Morality,
		Colleagues = shift.Colleagues,
		Accomplishments = shift.Accomplishments,
		Happiness = shift.Happiness,
	}
	for _, jobEnd in rule.Ends do
		local value = stats[jobEnd.Stat]
		if (jobEnd.IsHigh and value >= rule.MaxStat) or (not jobEnd.IsHigh and value <= 0) then
			return jobEnd.Text .. rule.EndSuffix
		end
	end
	return nil
end

-- the first card of a shift is answered whenever, every one after it is up for a while first
function Util.getIfReady(rule: Rule, shift: Shift, now: number): boolean
	local answeredAt = shift.AnsweredAt
	return answeredAt == nil or now - answeredAt >= rule.ReadDuration
end

-- the next card is asked. none comes twice before all of the job's were up, then they're shuffled anew: the old
-- place meant to + only ever kept its first card from coming back
function Util.draw(shift: Shift, cards: { Card }, random: Random): Shift
	assert(#cards > 0, `a job without a card`)
	local deck = table.clone(shift.Deck)
	if #deck == 0 then
		deck = shuffle(cards, random)
		-- the one that was just answered isn't the first of the new round where there's another to ask
		if #deck > 1 and deck[#deck] == shift.Card then
			deck[1], deck[#deck] = deck[#deck], deck[1]
		end
	end
	local out = table.clone(shift)
	out.Card = table.remove(deck) :: Card
	out.Deck = table.freeze(deck)
	return table.freeze(out)
end

function Util.new(rule: Rule, jobId: JobId, cards: { Card }, random: Random): Shift
	assert(#cards > 0, `a job without a card`)
	local deck = shuffle(cards, random)
	local shift: Shift = {
		JobId = jobId,
		Card = table.remove(deck) :: Card,
		Morality = rule.StartStat,
		Colleagues = rule.StartStat,
		Accomplishments = rule.StartStat,
		Happiness = rule.StartStat,
		AnswerCount = 0,
		Paycheck = 0,
		AnsweredAt = nil,
		EndText = nil,
		Deck = table.freeze(deck),
	}
	return table.freeze(shift)
end

-- a yes adds what the card has for each of the four, a no takes it off. then the answer is paid, the next card is
-- asked + the shift is looked at for an end, in the order the old place went through them. whether the answer is
-- taken at all is whoever calls this to ask first
function Util.answer(rule: Rule, shift: Shift, isYes: boolean, cards: { Card }, random: Random, now: number): Shift
	assert(shift.EndText == nil, `the shift is over`)
	local card = shift.Card
	local sign = if isYes then 1 else -1
	local out = table.clone(Util.draw(shift, cards, random))
	out.Morality = move(rule, shift.Morality, card.Morality * sign)
	out.Colleagues = move(rule, shift.Colleagues, card.Colleagues * sign)
	out.Accomplishments = move(rule, shift.Accomplishments, card.Accomplishments * sign)
	out.Happiness = move(rule, shift.Happiness, card.Happiness * sign)
	out.AnswerCount = shift.AnswerCount + 1
	out.Paycheck = Util.getPay(rule, shift.Paycheck, out.AnswerCount)
	out.AnsweredAt = now
	out.EndText = Util.getEnd(rule, out)
	return table.freeze(out)
end

-- what a client is told of a shift. readyAt is on the clock the clients share with the server
function Util.getShown(shift: Shift, readyAt: number): JobShift
	return table.freeze({
		JobId = shift.JobId,
		Text = shift.EndText or shift.Card.Text,
		Morality = shift.Morality,
		Colleagues = shift.Colleagues,
		Accomplishments = shift.Accomplishments,
		Happiness = shift.Happiness,
		Paycheck = shift.Paycheck,
		ReadyAt = readyAt,
		IsOver = shift.EndText ~= nil,
	})
end

return Util
