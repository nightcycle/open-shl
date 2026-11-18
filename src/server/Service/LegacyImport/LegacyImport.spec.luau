--!strict
-- Services
local HttpService = game:GetService("HttpService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FakeDataStoreUtil = require("@game/ServerScriptService/Server/Util/FakeDataStore")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local LegacyImportService = require("@game/ServerScriptService/Server/Service/LegacyImport")
local LegacyStoreDefinition = require("@game/ServerScriptService/Server/Definition/LegacyStore")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
type ReadOnlyStore<V> = StoreDefinition.ReadOnlyStore<V>
type LegacyImportService = LegacyImportService.LegacyImportService
type FakeDataStoreService = FakeDataStoreUtil.FakeDataStoreService
-- Constants
-- nobody who's in a play-test, so nothing of theirs gets through the text filter
local USER_ID = 1
local STARTING_BALANCES = ProductDefinition.STARTING_BALANCES
-- in the order they're asked
local STORE_NAMES = table.freeze({
	LegacyStoreDefinition.Characters.Name,
	LegacyStoreDefinition.LastCharacterId.Name,
	LegacyStoreDefinition.Credits.Name,
	LegacyStoreDefinition.Gems.Name,
	LegacyStoreDefinition.WornArtifact.Name,
	LegacyStoreDefinition.Furniture.Name,
	LegacyStoreDefinition.BaseLayout.Name,
	LegacyStoreDefinition.Tutorial.Name,
	LegacyStoreDefinition.DailyReward.Name,
})
-- what the old game stored in place of a slot that wasn't there
local NOTHING = "None"
-- the 12 numbers of a CFrame the way a piece of a base was stored
local PIECE_COMPONENTS = table.freeze({ 0, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 })
-- Variables
-- References
local StarterSuits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/starter-suits") :: Folder
-- Private Functions
local function startData(): () -> ()
	assert(not DataService.IsInitialized, `the data service is already initialized`)
	return DataService.init()
end

local function startLegacyImport(): () -> ()
	assert(not LegacyImportService.IsInitialized, `the legacy import service is already initialized`)
	return LegacyImportService.init()
end

-- yields. the two services are up on a fake of their own for as long as fn runs + taken down again whatever comes of it
local function run(fn: (legacyImportService: LegacyImportService, fake: FakeDataStoreService) -> ())
	local destroyCallbacks: { () -> () } = {}
	local success, msg = pcall(function()
		table.insert(destroyCallbacks, startData())
		assert(DataService.IsInitialized, `the data service isn't initialized`)
		local fake = FakeDataStoreUtil.new()
		DataService:SetDataStoreService(fake)
		table.insert(destroyCallbacks, startLegacyImport())
		assert(LegacyImportService.IsInitialized, `the legacy import service isn't initialized`)
		fn(LegacyImportService, fake)
	end)
	for index = #destroyCallbacks, 1, -1 do
		destroyCallbacks[index]()
	end
	if not success then
		error(msg, 0)
	end
end

-- writes a value the way the old game left it for the user
local function plant<V>(fake: FakeDataStoreService, store: ReadOnlyStore<V>, value: unknown)
	fake:Plant(store.Name, store.GetKey(USER_ID), value)
end

-- a slot of a save is its id + the two identities of a starter suit
local function newSlot(id: string, suitIndex: number): { unknown }
	local module = StarterSuits:FindFirstChild(`Suit{suitIndex}`)
	assert(module and module:IsA("ModuleScript"), `no starter suit {suitIndex}`)
	-- required by instance, rojo turns each json into a module
	local suit = require(module) :: any
	return { id, suit[1], suit[2] }
end
-- Class
return {
	-- a user the old stores hold nothing of gets an empty patch, their save keeps what it starts out with
	Nothing = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			local patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `nothing wasn't imported: {tostring(patchRes.Value)}`)
			assert(next(patchRes.Value) == nil, `a patch was made out of nothing`)
			assert(table.isfrozen(patchRes.Value), `the patch isn't frozen`)
			-- every store is asked once + none of them is ever written to
			local calls = fake:GetCalls()
			assert(#calls == #STORE_NAMES, `the old stores were called {#calls} times`)
			for index, storeName in STORE_NAMES do
				local call = calls[index]
				assert(
					call.Method == "GetAsync" and call.StoreName == storeName and call.Key == `user_{USER_ID}`,
					`call {index} wasn't a read of "{storeName}"`
				)
			end
		end)
	end),

	-- a balance is a whole number that's never under 0, the old game didn't see to either
	Balances = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			plant(fake, LegacyStoreDefinition.Credits, 120.7)
			local patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `the credits weren't imported: {tostring(patchRes.Value)}`)
			-- a store that was never written stood for what a new player starts out with
			assert(
				SpecUtil.getIfEqual(patchRes.Value.Balances, { Credits = 120, Gems = STARTING_BALANCES.Gems }),
				`the credits came out wrong`
			)
			assert(
				patchRes.Value.Characters == nil and patchRes.Value.Inventory == nil,
				`more than the balances came out`
			)

			plant(fake, LegacyStoreDefinition.Credits, -40)
			plant(fake, LegacyStoreDefinition.Gems, 3.99)
			patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `the gems weren't imported: {tostring(patchRes.Value)}`)
			assert(SpecUtil.getIfEqual(patchRes.Value.Balances, { Credits = 0, Gems = 3 }), `a debt came out wrong`)
		end)
	end),

	Settings = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			-- the old game stored whatever a client sent it for the tutorial
			for _, tutorial: unknown in { true, false, "yes", 1 } :: { unknown } do
				plant(fake, LegacyStoreDefinition.Tutorial, tutorial)
				local patchRes = legacyImportService:Import(USER_ID)
				assert(patchRes.IsOk, `a tutorial of {tostring(tutorial)} wasn't imported`)
				assert(
					patchRes.Value.IsTutorialEnabled == (if type(tutorial) == "boolean" then tutorial else nil),
					`a tutorial of {tostring(tutorial)} came out wrong`
				)
			end

			plant(fake, LegacyStoreDefinition.DailyReward, 1700000000.75)
			local patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk and patchRes.Value.LastDailyRewardAt == 1700000000, `the daily reward came out wrong`)
			plant(fake, LegacyStoreDefinition.DailyReward, -5)
			patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk and patchRes.Value.LastDailyRewardAt == 0, `a daily reward before time came out wrong`)
			-- a time that's ahead of the clock would hold the next reward back for as long as it is
			plant(fake, LegacyStoreDefinition.DailyReward, os.time() + 86400)
			patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `a daily reward ahead of time wasn't imported: {tostring(patchRes.Value)}`)
			local lastDailyRewardAt = patchRes.Value.LastDailyRewardAt
			assert(lastDailyRewardAt and lastDailyRewardAt <= os.time(), `a daily reward ahead of time was kept`)
		end)
	end),

	Base = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			local furniture = FurnitureDefinition.list()[1]
			local theme: ThemeDefinition.ThemeDefinition? = nil
			for _, definition in ThemeDefinition.list() do
				if definition.Id ~= ThemeDefinition.DEFAULT_ID then
					theme = definition
					break
				end
			end
			assert(furniture and theme, `the game is short of furniture or themes`)
			local layout = HttpService:JSONEncode({
				theme.Name :: any,
				"a title that was never used",
				{ 1 :: any, furniture.Name, PIECE_COMPONENTS },
			})

			-- the old game placed whatever a client asked for, here a piece + a theme take owning them
			plant(fake, LegacyStoreDefinition.BaseLayout, layout)
			local patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `a base wasn't imported: {tostring(patchRes.Value)}`)
			assert(patchRes.Value.Inventory == nil, `an inventory came out of a store that was never written`)
			local bareLayout = patchRes.Value.BaseLayout
			assert(bareLayout, `no base came out`)
			assert(
				bareLayout.ThemeId == ThemeDefinition.DEFAULT_ID and #bareLayout.Furniture == 0,
				`a base came out with what its player doesn't own`
			)

			plant(fake, LegacyStoreDefinition.Furniture, { furniture.Name, theme.Name })
			patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `a base wasn't imported with its purchases: {tostring(patchRes.Value)}`)
			local inventory, baseLayout = patchRes.Value.Inventory, patchRes.Value.BaseLayout
			assert(inventory and baseLayout, `no base came out with its purchases`)
			assert(SpecUtil.getIfEqual(inventory.FurnitureIds, { furniture.Id }), `the furniture that's owned is off`)
			assert(table.find(inventory.ThemeIds, theme.Id), `the theme that's owned is missing`)
			assert(baseLayout.ThemeId == theme.Id, `the base has the "{baseLayout.ThemeId}" theme`)
			assert(
				#baseLayout.Furniture == 1 and baseLayout.Furniture[1].FurnitureId == furniture.Id,
				`the piece that was placed is missing`
			)

			-- a value that can't be read is left out like anything else that's broken
			plant(fake, LegacyStoreDefinition.BaseLayout, "not json")
			patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsOk, `a base that isn't json ended the import: {tostring(patchRes.Value)}`)
			assert(patchRes.Value.BaseLayout == nil and patchRes.Value.Inventory, `a base that isn't json came out`)
		end)
	end),

	-- a save that held no slot that can be read keeps the characters it starts out with
	NoCharacters = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			plant(fake, LegacyStoreDefinition.Credits, 75)
			plant(fake, LegacyStoreDefinition.LastCharacterId, NOTHING)
			local values: { [string]: string } = {
				["a text that isn't json"] = "not json",
				["json that isn't a list"] = HttpService:JSONEncode({ Slot = NOTHING }),
				["a list without a slot"] = HttpService:JSONEncode({}),
				["a list of empty slots"] = HttpService:JSONEncode({ NOTHING, NOTHING }),
			}
			for name, value in values do
				plant(fake, LegacyStoreDefinition.Characters, value)
				local patchRes = legacyImportService:Import(USER_ID)
				assert(patchRes.IsOk, `{name} ended the import: {tostring(patchRes.Value)}`)
				assert(
					patchRes.Value.Characters == nil and patchRes.Value.ActiveCharacterId == nil,
					`characters came out of {name}`
				)
				assert(patchRes.Value.Balances and patchRes.Value.Balances.Credits == 75, `{name} cost the credits`)
			end
		end)
	end),

	-- the old game left it to the client to have a name + a backstory filtered, one that can't be filtered here
	-- doesn't make it over the way it was stored
	Unfiltered = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			plant(fake, LegacyStoreDefinition.Characters, HttpService:JSONEncode({ newSlot("slot-a", 1) }))
			local patchRes = legacyImportService:Import(USER_ID)
			assert(patchRes.IsErr, `the texts of a user who isn't here were imported`)
			assert(string.find(patchRes.Value, "filtered", 1, true), `the import err: {patchRes.Value}`)
		end)
	end),

	-- an error means the old stores couldn't be asked, an import that went on without one would lose what it holds
	-- for good
	Unreachable = SpecUtil.newScenario(function()
		run(function(legacyImportService: LegacyImportService, fake: FakeDataStoreService)
			plant(fake, LegacyStoreDefinition.Credits, 75)
			plant(fake, LegacyStoreDefinition.Gems, "plenty")
			assert(legacyImportService:Import(USER_ID).IsErr, `gems that aren't a number were imported`)

			plant(fake, LegacyStoreDefinition.Gems, 5)
			local store = LegacyStoreDefinition.DailyReward
			fake:FailKey(store.Name, store.GetKey(USER_ID), "Error")
			local patchRes = legacyImportService:Import(USER_ID)
			fake:FailKey(store.Name, store.GetKey(USER_ID), nil)
			assert(patchRes.IsErr, `a patch was made without one of the old stores`)

			local againRes = legacyImportService:Import(USER_ID)
			assert(againRes.IsOk, `the import didn't work once the store was back: {tostring(againRes.Value)}`)
			assert(SpecUtil.getIfEqual(againRes.Value.Balances, { Credits = 75, Gems = 5 }), `the balances are off`)
		end)
	end),
}
