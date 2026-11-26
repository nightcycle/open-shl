--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Currency = EconomyType.Currency
type PlayerSave = SaveType.PlayerSave

local Types = {}

-- a word that pays out once for whoever types it. the server alone knows them: the old place shipped its table to
-- every client, so a code was public the day it was added
export type CodeDefinition = {
	-- what a save keeps of it
	Id: string,
	-- what's typed. it's also the word the old place stored, which is what an import matches on
	Text: string,
	Currency: Currency,
	Amount: number,
}
Types.CodeDefinition = Type.strictInterface({
	Id = Type.string,
	Text = Type.string,
	Currency = EconomyType.Currency,
	Amount = Type.intersection(Type.integer, Type.numberPositive),
})

-- the codes of a game + where its save keeps the ones that were paid out
export type CodeCatalogue = {
	Definitions: { CodeDefinition },
	-- the list of the save itself, so whoever is handed a save to write may add to it. nil for a save that keeps none
	getRedeemedIds: (save: PlayerSave) -> { string }?,
}
Types.CodeCatalogue = Type.strictInterface({
	Definitions = Type.array(Types.CodeDefinition),
	getRedeemedIds = Type.callback,
})

return Types
