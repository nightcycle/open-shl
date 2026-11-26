--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local JobType = require("@game/ServerScriptService/Server/Type/Job")
local SharedJobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type Card = JobType.Card
type Decks = JobType.Decks
type JobId = SharedJobType.JobId
export type Rule = JobType.Rule
-- Constants
-- the jobs of a game are its own, the rule of another game is never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		error(`shl1 has no jobs`)
	end,
	shl2 = function(): Rule
		error(`shl2 has no jobs`)
	end,
	shl3 = function(): Rule
		return require("@self/SHL3")
	end,
})
assert(JobType.Rule(RULE))
assert(RULE.StartStat < RULE.MaxStat, `a shift starts at {RULE.StartStat} of {RULE.MaxStat}`)
TableUtil.deepFreeze(RULE)
-- Variables
-- References
-- rojo turns each json file of the game's data into a module. the cards stay with the server: a client is sent the
-- text of one at a time + never what an answer does
local DecksModule = IndexUtil.waitForPath("game/ServerScriptService/Data/job") :: ModuleScript
-- Private Functions
-- a table that's off stops the server as it starts, a shift would have fallen over on its first card otherwise
local function getDecks(): Decks
	local decks = require(DecksModule) :: unknown
	local success, msg = JobType.Decks(decks)
	assert(success, `the cards of the jobs: {msg}`)
	TableUtil.deepFreeze(decks :: Decks)
	return decks :: Decks
end

-- what a job asks: the cards it has to itself, then the ones every job has
local function newDeck(decks: Decks, jobId: JobId): { Card }
	local cards: { Card } = table.clone(decks[jobId])
	table.move(decks.Misc, 1, #decks.Misc, #cards + 1, cards)
	return table.freeze(cards)
end
-- Class
local DECKS: Decks = getDecks()
local CARDS: { [JobId]: { Card } } = table.freeze({
	Teacher = newDeck(DECKS, "Teacher"),
	Doctor = newDeck(DECKS, "Doctor"),
	Mentor = newDeck(DECKS, "Mentor"),
	Businessperson = newDeck(DECKS, "Businessperson"),
})
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	RULE = RULE,
	-- the cards as the file has them, each job's apart from the ones all of them ask
	DECKS = DECKS,
}

-- every card a shift of the job goes through before one comes up again
Module.getCards = function(jobId: JobId): { Card }
	return CARDS[jobId]
end

return Module
