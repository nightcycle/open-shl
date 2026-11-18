--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Types
local Types = {}

export type QuestStatus = "Active" | "Succeeded" | "Failed"
Types.QuestStatus = Type.literal("Active", "Succeeded", "Failed")

export type QuestState = {
	Type: PseudoEnum.QuestType,
	Instruction: string, -- the line of the quest giver, the banner wraps it in quotes
	SecondsRemaining: number,
	Status: QuestStatus,
}
Types.QuestState = Type.strictInterface({
	Type = Type.literal(table.unpack(PseudoEnum.getEnumItems("QuestType"))),
	Instruction = Type.string,
	SecondsRemaining = Type.numberMin(0),
	Status = Types.QuestStatus,
})

export type QuestReward = {
	Currency: PseudoEnum.Currency,
	Amount: number,
}
Types.QuestReward = Type.strictInterface({
	Currency = Type.literal(table.unpack(PseudoEnum.getEnumItems("Currency"))),
	Amount = Type.numberMin(0),
})

export type QuestDefinition = {
	Type: PseudoEnum.QuestType,
	Prompt: string, -- what the player asks the quest giver
	Instruction: string, -- what the quest giver answers, "%s" stands for the name of the goal
	HasGoal: boolean, -- an item to find or a player to defeat
	Duration: number,
	MinPlayerCount: number, -- how many players the server needs before the quest can start
	IsTimeoutSuccess: boolean, -- running out of time wins the quest instead of failing it
	Credits: number,
	Gems: number,
}
Types.QuestDefinition = Type.strictInterface({
	Type = Type.literal(table.unpack(PseudoEnum.getEnumItems("QuestType"))),
	Prompt = Type.string,
	Instruction = Type.string,
	HasGoal = Type.boolean,
	Duration = Type.numberPositive,
	MinPlayerCount = Type.numberPositive,
	IsTimeoutSuccess = Type.boolean,
	Credits = Type.numberMin(0),
	Gems = Type.numberMin(0),
})

return Types
