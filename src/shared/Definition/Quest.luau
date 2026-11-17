--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
local Result = TypeUnionLib.Result
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
type Option<V> = TypeUnionLib.Option<V>
type Result<V, E> = TypeUnionLib.Result<V, E>
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
export type QuestDefinition = QuestType.QuestDefinition
export type QuestReward = QuestType.QuestReward
-- Constants
local DURATION = 300
-- only the survive quest counts heads, a target quest with nobody to hunt gets the NO_TARGET line instead
local DEFINITIONS: { [PseudoEnum.QuestType]: QuestDefinition } = {
	Find = {
		Type = PseudoEnum.QuestType.Find,
		Prompt = "Do you need me to find something?",
		Instruction = "Yes I do, the %s was lost - find it and be rewarded.",
		HasGoal = true,
		Duration = DURATION,
		MinPlayerCount = 1,
		IsTimeoutSuccess = false,
		Credits = 100,
		Gems = 5,
	},
	Survive = {
		Type = PseudoEnum.QuestType.Survive,
		Prompt = "I'm being hunted, help me!",
		Instruction = "To test you I have set a bounty on you, if you survive the next five minutes I'll reward you.",
		HasGoal = false,
		Duration = DURATION,
		MinPlayerCount = 2,
		IsTimeoutSuccess = true,
		Credits = 240,
		Gems = 12,
	},
	Target = {
		Type = PseudoEnum.QuestType.Target,
		Prompt = "Do you need me to defeat anyone?",
		Instruction = "Yes I do. %s has gotten too powerful - put a stop to them.",
		HasGoal = true,
		Duration = DURATION,
		MinPlayerCount = 1,
		IsTimeoutSuccess = false,
		Credits = 180,
		Gems = 9,
	},
}
TableUtil.deepFreeze(DEFINITIONS)
-- out of a hundred
local REWARD_BALLOTS = table.freeze({
	ARTIFACT = 10,
	GEMS = 20,
	CREDITS = 70,
})
local ARTIFACT_RARITY_BALLOTS: { [PseudoEnum.Rarity]: number } = table.freeze({
	VeryCommon = 490,
	Common = 300,
	Uncommon = 160,
	Rare = 50,
	Legendary = 6,
})
local DIALOG = table.freeze({
	GREETING = "I have a mission for you, are you up for it?",
	GOODBYE = "Leave, they're watching.",
	HAS_QUEST = "Complete your first quest.",
	NO_PLAYERS = "You're the only person in this server..",
	NO_TARGET = "Not at the moment - ask me again later!",
})
-- the name shown in the instruction, the map holds a copy of every item at each of its 13 hiding spots
local FIND_ITEMS: { string } = table.freeze({
	"Sword of Nefertiti",
	"Harbinger of Fimbuilwinter",
	"Spec Alpha Biograft Energy Sword",
	"Darkheart",
	"Classic Brigand's Sword",
	"Banhammer",
	"Bat Knight Bat Sword",
	"Scepter of Pharoahs",
	"Illumia",
})
-- every copy after the first is named "<item>_<n>"
local FIND_ITEM_COPY_PATTERN = "^(.+)_%d+$"
local COUNTDOWN_MINUTE_FORMAT = "%d:%02d"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

for questType, DEFINITION in DEFINITIONS do
	assert(QuestType.QuestDefinition(DEFINITION))
	assert(DEFINITION.Type == questType, `"{questType}" quest is filed under the wrong type`)
end

Module.DURATION = DURATION
Module.DIALOG = DIALOG
Module.FIND_ITEMS = FIND_ITEMS
-- where the map keeps the quest giver + the hidden items, for IndexUtil
Module.QUEST_GIVER_PATH = "game/Workspace/Map/quest-guy"
Module.FIND_ITEM_PATH = "game/Workspace/Map/find-quest"

Module.get = function(questType: PseudoEnum.QuestType): QuestDefinition
	return DEFINITIONS[questType]
end

-- goalName is the item to find or the alias of the target, quests without a goal ignore it
Module.formatInstruction = function(questType: PseudoEnum.QuestType, goalName: string?): Result<string, string>
	local definition = DEFINITIONS[questType]
	if not definition.HasGoal then
		return Result.ok(definition.Instruction)
	end
	if goalName == nil or goalName == "" then
		return Result.err(`"{questType}" quest has no goal to name`)
	end
	return Result.ok(definition.Instruction:format(goalName))
end

-- a target is called by the name of the identity they wear, players that never named it get a made up one
Module.getTargetAlias = function(identityName: string?, userName: string): string
	if identityName ~= nil and identityName ~= "" then
		return identityName
	end
	return `Super {userName}`
end

Module.getFindItemName = function(instanceName: string): Option<string>
	local name = instanceName:match(FIND_ITEM_COPY_PATTERN) or instanceName
	if table.find(FIND_ITEMS, name) == nil then
		return Option.none()
	end
	return Option.some(name)
end

Module.rollArtifactRarity = function(rng: Random): PseudoEnum.Rarity
	local rarities = PseudoEnum.getEnumItems("Rarity")
	local ballotCount = 0
	for _, rarity: PseudoEnum.Rarity in rarities do
		ballotCount += ARTIFACT_RARITY_BALLOTS[rarity]
	end
	local ballot = rng:NextInteger(1, ballotCount)
	for _, rarity: PseudoEnum.Rarity in rarities do
		ballot -= ARTIFACT_RARITY_BALLOTS[rarity]
		if ballot <= 0 then
			return rarity
		end
	end
	return rarities[#rarities]
end

Module.rollReward = function(questType: PseudoEnum.QuestType, rng: Random): QuestReward
	local definition = DEFINITIONS[questType]
	local ballot = rng:NextInteger(1, REWARD_BALLOTS.ARTIFACT + REWARD_BALLOTS.GEMS + REWARD_BALLOTS.CREDITS)
	local out: QuestReward
	if ballot <= REWARD_BALLOTS.ARTIFACT then
		out = {
			Type = "Artifact",
			Rarity = Module.rollArtifactRarity(rng),
		}
	elseif ballot <= REWARD_BALLOTS.ARTIFACT + REWARD_BALLOTS.GEMS then
		out = {
			Type = "Currency",
			Currency = PseudoEnum.Currency.Gems,
			Amount = definition.Gems,
		}
	else
		out = {
			Type = "Currency",
			Currency = PseudoEnum.Currency.Credits,
			Amount = definition.Credits,
		}
	end
	table.freeze(out)
	return out
end

-- the last minute counts down in bare seconds
Module.formatCountdown = function(secondsRemaining: number): string
	local seconds = math.max(0, math.ceil(secondsRemaining))
	if seconds <= 60 then
		return `{seconds}`
	end
	return COUNTDOWN_MINUTE_FORMAT:format(seconds // 60, seconds % 60)
end

return Module
