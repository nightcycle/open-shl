--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RandomCharacter = require("@game/ServerScriptService/Server/Random/Character/SHL3")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Types
local CharacterRollType = require("@game/ServerScriptService/Server/Type/CharacterRoll")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
type Entry = CharacterRollType.Entry
type Source = CharacterRollType.Source
type Tables = CharacterRollType.Tables
-- an entry the way the catalogue file spells it, of which only what a roll goes by is read
type CatalogueEntry = {
	ItemIds: { string },
	IsStarter: boolean,
}
-- Constants
local isCatalogue = Type.interface({
	Entries = Type.array(Type.interface({
		ItemIds = Type.array(Type.string),
		IsStarter = Type.boolean,
	})),
})
-- Variables
-- no two servers deal out the same characters
local Rng = Random.new()
-- read the first time it's asked for
local Source: Source? = nil
-- References
-- rojo turns each json file of the game's data into a module
local TablesModule = IndexUtil.waitForPath("game/ServerScriptService/Data/random-character") :: ModuleScript
local CatalogueModule = IndexUtil.waitForPath("game/ServerScriptService/Data/catalogue/entry") :: ModuleScript
-- Private Functions
-- nobody owns anything they weren't handed yet, so what a roll is dealt from is what every player starts out with
local function getSource(): Source
	if Source then
		return Source
	end
	local tables = require(TablesModule) :: unknown
	assert(CharacterRollType.Tables(tables))
	local catalogue = require(CatalogueModule) :: unknown
	assert(isCatalogue(catalogue))
	local entries: { Entry } = {}
	for _, catalogueEntry: CatalogueEntry in (catalogue :: any).Entries do
		table.insert(entries, {
			ItemIds = catalogueEntry.ItemIds,
			IsOwned = catalogueEntry.IsStarter,
		})
	end
	-- an item that's kept out of every roll by a misspelt id would be dealt without a word
	for _, itemId in (tables :: Tables).NeverRolled do
		assert(
			ItemAppearanceDefinition.get(itemId).IsOk,
			`the item "{itemId}" that's never rolled isn't in the library`
		)
	end
	for _, forcedPower in (tables :: Tables).ForcedPowers do
		assert(
			ItemAppearanceDefinition.get(forcedPower.ItemId).IsOk,
			`the item "{forcedPower.ItemId}" that calls for a power isn't in the library`
		)
	end
	local out: Source = {
		Tables = tables :: Tables,
		Entries = entries,
	}
	assert(CharacterRollType.Source(out))
	TableUtil.deepFreeze(out)
	Source = out
	return out
end

-- the game never had a starter character: whoever needed one was dealt one, + got to change all of it
local function new(): Character
	return RandomCharacter.Character(getSource(), RandomUtil.newSeed(Rng))
end

-- a new player finds every slot they have filled
local function list(): { Character }
	local out: { Character } = {}
	for _ = 1, ProductDefinition.getCharacterSlotCount({}) do
		table.insert(out, new())
	end
	return out
end
-- Class
-- a table that's off stops the server as it starts, not the first player who joins it
getSource()

return table.freeze({
	List = list,
	New = new,
})
