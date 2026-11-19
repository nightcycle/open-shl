--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local LegacyDataMigration = require("@game/ServerScriptService/Server/Util/LegacyDataMigration")
local LegacyStoreDefinition = require("@game/ServerScriptService/Server/Definition/LegacyStore")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
local TextFilterUtil = require("@game/ServerScriptService/Server/Util/TextFilter")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
type ReadOnlyStore<V> = StoreDefinition.ReadOnlyStore<V>
type Character = CharacterType.Character
type SavePatch = LegacyImportType.SavePatch
type Importer = LegacyImportType.Importer
-- what each of the old stores holds for a player, nil where it holds nothing
type Stored = {
	Characters: string?,
	LastCharacterId: string?,
	Credits: number?,
	Gems: number?,
	WornArtifact: LegacyDataMigration.WornArtifact?,
	Furniture: { string }?,
	BaseLayout: string?,
	Tutorial: unknown,
	DailyReward: number?,
}
-- Constants
local STARTING_BALANCES = ProductDefinition.STARTING_BALANCES
local FILTER_TIMEOUT = 5
-- a save a client tampered with can be wrong in every entry it has
local MAX_WARNINGS = 10
-- Variables
-- References
-- Private Functions
-- yields
local function read<V>(store: ReadOnlyStore<V>, userId: number): Result<Option<V>, string>
	if not DataService.IsInitialized then
		return Result.err(`the data service isn't initialized`)
	end
	return DataService:Read(store, userId)
end

-- yields. everything is asked for before any of it is used: a store that can't be reached ends the import, it's
-- tried again from the start the next time the player joins
local function readStores(userId: number): Result<Stored, string>
	local charactersRes = read(LegacyStoreDefinition.Characters, userId)
	if charactersRes.IsErr then
		return charactersRes
	end
	local lastCharacterIdRes = read(LegacyStoreDefinition.LastCharacterId, userId)
	if lastCharacterIdRes.IsErr then
		return lastCharacterIdRes
	end
	local creditsRes = read(LegacyStoreDefinition.Credits, userId)
	if creditsRes.IsErr then
		return creditsRes
	end
	local gemsRes = read(LegacyStoreDefinition.Gems, userId)
	if gemsRes.IsErr then
		return gemsRes
	end
	local wornArtifactRes = read(LegacyStoreDefinition.WornArtifact, userId)
	if wornArtifactRes.IsErr then
		return wornArtifactRes
	end
	local furnitureRes = read(LegacyStoreDefinition.Furniture, userId)
	if furnitureRes.IsErr then
		return furnitureRes
	end
	local baseLayoutRes = read(LegacyStoreDefinition.BaseLayout, userId)
	if baseLayoutRes.IsErr then
		return baseLayoutRes
	end
	local tutorialRes = read(LegacyStoreDefinition.Tutorial, userId)
	if tutorialRes.IsErr then
		return tutorialRes
	end
	local dailyRewardRes = read(LegacyStoreDefinition.DailyReward, userId)
	if dailyRewardRes.IsErr then
		return dailyRewardRes
	end
	return Result.ok({
		Characters = charactersRes.Value.Value,
		LastCharacterId = lastCharacterIdRes.Value.Value,
		Credits = creditsRes.Value.Value,
		Gems = gemsRes.Value.Value,
		WornArtifact = wornArtifactRes.Value.Value,
		Furniture = furnitureRes.Value.Value,
		BaseLayout = baseLayoutRes.Value.Value,
		Tutorial = tutorialRes.Value.Value,
		DailyReward = dailyRewardRes.Value.Value,
	})
end

-- what didn't make it over is only ever said here, the old stores stay as they are for whoever looks into it
local function report(userId: number, store: ReadOnlyStore<any>, problems: { string })
	for index, problem in problems do
		if index > MAX_WARNINGS then
			warn(`legacy import of {userId} left out {#problems - MAX_WARNINGS} more of "{store.Name}"`)
			break
		end
		warn(`legacy import of {userId} left out "{store.Name}" {problem}`)
	end
end

-- a value that can't be read is left out like anything else that's broken, asking for it again wouldn't change it
local function decodeList(userId: number, store: ReadOnlyStore<string>, json: string?): { [number]: unknown }?
	if json == nil then
		return nil
	end
	local listRes = LegacyStoreDefinition.decodeList(json)
	if listRes.IsErr then
		report(userId, store, { `all of it: {listRes.Value}` })
		return nil
	end
	return listRes.Value
end

-- a balance is a whole number that's never under 0, the old game didn't see to either
local function toBalance(amount: number): number
	return math.max(0, math.floor(amount))
end

-- yields. the old game left it to the client to have a name + a backstory filtered, so none of them is taken over the
-- way it was stored
local function filterCharacters(characters: { Character }, userId: number): Result<{ Character }, string>
	local filteredTexts: { [string]: string } = {}
	for _, character in characters do
		for _, identity in character.Identities do
			if not identity then
				continue
			end
			for _, text in { identity.Profile.Name, identity.Profile.Backstory } do
				if text == "" or filteredTexts[text] then
					continue
				end
				local f = Future.timeout(TextFilterUtil.filter(text, userId), FILTER_TIMEOUT)
				if f.IsCanceled then
					return Result.err(`the filter took too long`)
				end
				local textRes: Result<string, string> = f.Value
				if textRes.IsErr then
					return Result.err(textRes.Value)
				end
				filteredTexts[text] = textRes.Value
			end
		end
	end
	local out: { Character } = {}
	for index, character in characters do
		out[index] = FreezeUtil.delta(character, function(t: Character): Character
			for _, identity in t.Identities do
				if not identity then
					continue
				end
				local profile = identity.Profile
				local name = filteredTexts[profile.Name] or ""
				-- a name the filter blanked out reads as unset, the name tag shows the user name for it
				profile.Name = if string.match(name, "^#+$") then "" else name
				profile.Backstory = filteredTexts[profile.Backstory] or ""
			end
			return t
		end)
	end
	return Result.ok(out)
end

-- yields. a user the old stores hold nothing of gets an empty patch, an error means they couldn't be asked
local function import(userId: number): Result<SavePatch, string>
	local storedRes = readStores(userId)
	if storedRes.IsErr then
		return Result.err(`the old stores couldn't be read: {storedRes.Value}`)
	end
	local stored = storedRes.Value
	local patch: SavePatch = {}

	local characters: { Character } = {}
	local slots = decodeList(userId, LegacyStoreDefinition.Characters, stored.Characters)
	if slots then
		local problems: { string }
		characters, problems = LegacyDataMigration.toCharacters(slots)
		report(userId, LegacyStoreDefinition.Characters, problems)
	end
	-- a save that held no slot that can be read keeps the characters it starts out with
	if #characters > 0 then
		-- the old game fell back to the first slot too when the one that was played last was gone
		local activeIndex = 1
		for index, character in characters do
			if character.Id == stored.LastCharacterId then
				activeIndex = index
			end
		end
		if stored.WornArtifact then
			local wornRes = LegacyDataMigration.wearArtifact(characters[activeIndex], stored.WornArtifact)
			if wornRes.IsOk then
				characters[activeIndex] = wornRes.Value
			else
				report(userId, LegacyStoreDefinition.WornArtifact, { `worn artifact: {wornRes.Value}` })
			end
		end
		local charactersRes = filterCharacters(characters, userId)
		if charactersRes.IsErr then
			return Result.err(`the text of the old characters couldn't be filtered: {charactersRes.Value}`)
		end
		patch.Characters = charactersRes.Value
		patch.ActiveCharacterId = characters[activeIndex].Id
	end

	if stored.Credits or stored.Gems then
		-- a store that was never written stood for what a new player starts out with
		patch.Balances = {
			Credits = toBalance(stored.Credits or STARTING_BALANCES.Credits),
			Gems = toBalance(stored.Gems or STARTING_BALANCES.Gems),
		}
	end

	local inventory, inventoryProblems = LegacyDataMigration.toInventory(stored.Furniture or {})
	if stored.Furniture then
		report(userId, LegacyStoreDefinition.Furniture, inventoryProblems)
		patch.Inventory = inventory
	end
	local baseEntries = decodeList(userId, LegacyStoreDefinition.BaseLayout, stored.BaseLayout)
	if baseEntries then
		local baseLayout, problems = LegacyDataMigration.toBaseLayout(baseEntries, inventory)
		report(userId, LegacyStoreDefinition.BaseLayout, problems)
		patch.BaseLayout = baseLayout
	end

	if type(stored.Tutorial) == "boolean" then
		patch.IsTutorialEnabled = stored.Tutorial
	end
	if stored.DailyReward then
		-- a time that's ahead of the clock would hold the next reward back for as long as it is
		patch.LastDailyRewardAt = math.clamp(math.floor(stored.DailyReward), 0, os.time())
	end

	TableUtil.deepFreeze(patch)
	return Result.ok(patch)
end
-- Class
-- the game superhero life 2 was before it was rewritten: its stores are in Definition/LegacyStore, what they hold is
-- made sense of by Util/LegacyDataMigration
local Importer: Importer = table.freeze({
	Version = 1,
	Import = import,
})

return Importer
