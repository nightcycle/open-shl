--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RandomCharacter = require("@game/ServerScriptService/Server/Random/Character/SHL3")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Types
local CharacterRollType = require("@game/ServerScriptService/Server/Type/CharacterRoll")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type Entry = CharacterRollType.Entry
type Owned = EconomyType.Owned
type Source = CharacterRollType.Source
type Tables = CharacterRollType.Tables
-- an entry the way the catalogue file spells it, of which only what a roll goes by + what it was sold for is read
type CatalogueEntry = {
	LegacyName: string,
	ItemIds: { string },
	IsStarter: boolean,
	Cost: number?,
}
type Catalogue = {
	Entries: { CatalogueEntry },
}
-- Constants
local isCatalogue = Type.interface({
	Entries = Type.array(Type.interface({
		LegacyName = Type.string,
		ItemIds = Type.array(Type.string),
		IsStarter = Type.boolean,
		Cost = Type.optional(Type.number),
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
-- the catalogue + what the game holds back are one truth written down twice: what nobody starts out with is listed
-- at the cost the file has for it, piece for piece, + nothing a new player has is. one that's off would sell a piece
-- at the wrong price or deal out what has to be bought
local function assertListed(entry: CatalogueEntry)
	local name = entry.LegacyName
	local listing: AccessDefinition.Listing? = nil
	for _, itemId in entry.ItemIds do
		local itemListing = AccessDefinition.getOf(itemId)
		assert(not entry.IsStarter or not itemListing, `the starter "{name}" is held back`)
		assert(entry.IsStarter or itemListing, `"{name}" is nobody's to start with + isn't listed`)
		assert(listing == nil or listing == itemListing, `the pieces of "{name}" are listed apart`)
		listing = itemListing
	end
	if not listing then
		return
	end
	local itemIds: { string } = listing.ItemIds or {}
	assert(#itemIds == #entry.ItemIds, `"{name}" isn't listed with the pieces the catalogue has for it`)
	assert(
		listing.Cost == (entry.Cost or 0),
		`"{name}" is listed at {listing.Cost}, the catalogue has {entry.Cost or 0}`
	)
end

-- what a new player is dealt from: nobody owns anything they weren't handed yet
local function getSource(): Source
	if Source then
		return Source
	end
	local tables = require(TablesModule) :: unknown
	assert(CharacterRollType.Tables(tables))
	local catalogue = require(CatalogueModule) :: unknown
	assert(isCatalogue(catalogue))
	local entries: { Entry } = {}
	for _, catalogueEntry in (catalogue :: Catalogue).Entries do
		assertListed(catalogueEntry)
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
		PowerIds = (tables :: Tables).StarterPowerIds,
	}
	assert(CharacterRollType.Source(out))
	TableUtil.deepFreeze(out)
	Source = out
	return out
end

-- what somebody who bought something is dealt from: an entry is theirs once one of its pieces is, + the powers they
-- bought are dealt beside the ones everybody has
local function getOwnedSource(owned: Owned?): Source
	local source = getSource()
	if not owned or (#owned.ItemIds == 0 and #owned.PowerIds == 0) then
		return source
	end
	local entries: { Entry } = {}
	for _, entry in source.Entries do
		local isOwned = entry.IsOwned
		for _, itemId in entry.ItemIds do
			isOwned = isOwned or table.find(owned.ItemIds, itemId) ~= nil
		end
		table.insert(
			entries,
			if isOwned == entry.IsOwned then entry else { ItemIds = entry.ItemIds, IsOwned = isOwned }
		)
	end
	local powerIds = table.clone(source.PowerIds)
	for _, powerId in owned.PowerIds do
		if not table.find(powerIds, powerId) then
			table.insert(powerIds, powerId)
		end
	end
	return {
		Tables = source.Tables,
		Entries = entries,
		PowerIds = powerIds,
	}
end

-- the game never had a starter character: whoever needed one was dealt one, + got to change all of it
local function new(owned: Owned?): Character
	return RandomCharacter.Character(getOwnedSource(owned), RandomUtil.newSeed(Rng))
end

local function roll(owned: Owned): Result<Character, string>
	return Result.ok(new(owned))
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
	Roll = roll,
})
