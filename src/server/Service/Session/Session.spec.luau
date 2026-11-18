--!strict
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FakeDataStoreUtil = require("@game/ServerScriptService/Server/Util/FakeDataStore")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local LegacyImportService = require("@game/ServerScriptService/Server/Service/LegacyImport")
local LegacyStoreDefinition = require("@game/ServerScriptService/Server/Definition/LegacyStore")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Character = CharacterType.Character
type PlayerSave = SaveType.PlayerSave
type Session = SessionService.Session
type FakeDataStoreService = FakeDataStoreUtil.FakeDataStoreService
type ReadOnlyStore<V> = StoreDefinition.ReadOnlyStore<V>
-- Constants
local STORE = StoreDefinition.Player
-- a session takes a player + the server has no way to make one up, so the walk waits for whoever play-tests
local PLAYER_TIMEOUT = 30
local SESSION_TIMEOUT = 30
-- the data service writes what changed every 30 seconds
local AUTOSAVE_TIMEOUT = 45
-- what the old stores hold of the player before their first visit
local SLOT_IDS = table.freeze({ "slot-1", "slot-2", "slot-3" })
local LAST_SLOT_INDEX = 2
local LAST_SLOT_NAME = "Snow Sister"
local CREDITS = 1234
local DAILY_REWARD_AT = 1700000000
-- the 12 numbers of a CFrame the way a piece of a base was stored
local PIECE_COMPONENTS = table.freeze({ 0, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 })
-- Variables
-- References
local StarterSuits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/starter-suits") :: Folder
-- Private Functions
local function startNetwork(): () -> ()
	assert(not NetworkService.IsInitialized, `the network service is already initialized`)
	return NetworkService.init()
end

local function startData(): () -> ()
	assert(not DataService.IsInitialized, `the data service is already initialized`)
	return DataService.init()
end

local function setDataStoreService(fake: FakeDataStoreService)
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	DataService:SetDataStoreService(fake)
end

local function startLegacyImport(): () -> ()
	assert(not LegacyImportService.IsInitialized, `the legacy import service is already initialized`)
	return LegacyImportService.init()
end

local function startSession(): () -> ()
	assert(not SessionService.IsInitialized, `the session service is already initialized`)
	return SessionService.init()
end

-- in the order the server starts them. a callback is added as its service is up, so whatever made it up by the time
-- one of them throws can still be taken down
local function start(destroyCallbacks: { () -> () }, fake: FakeDataStoreService)
	table.insert(destroyCallbacks, startNetwork())
	table.insert(destroyCallbacks, startData())
	setDataStoreService(fake)
	table.insert(destroyCallbacks, startLegacyImport())
	table.insert(destroyCallbacks, startSession())
end

-- yields. in the reverse order, the way the server stops them as it closes
local function stop(destroyCallbacks: { () -> () })
	for index = #destroyCallbacks, 1, -1 do
		destroyCallbacks[index]()
	end
	table.clear(destroyCallbacks)
end

-- yields
local function awaitPlayer(): Player
	local startTime = os.clock()
	while #Players:GetPlayers() == 0 do
		assert(os.clock() - startTime < PLAYER_TIMEOUT, `nobody joined, a session is only tested in a play-test`)
		task.wait()
	end
	return Players:GetPlayers()[1]
end

local function getSession(player: Player): Session?
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	return if sessionOpt.IsSome then sessionOpt.Value else nil
end

-- yields. a load that fails ends in a kick, so a player who's gone is a session that isn't coming
local function awaitSession(player: Player): Session
	local startTime = os.clock()
	while true do
		local session = getSession(player)
		if session then
			return session
		end
		assert(player.Parent ~= nil, `{player.Name} was kicked instead of handed a session`)
		assert(os.clock() - startTime < SESSION_TIMEOUT, `{player.Name} wasn't handed a session`)
		task.wait()
	end
end

local function update(player: Player, fn: (save: PlayerSave) -> PlayerSave?): PlayerSave
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local saveRes = SessionService:Update(player, fn)
	assert(saveRes.IsOk, `the save wasn't updated: {tostring(saveRes.Value)}`)
	return saveRes.Value
end

-- yields. what the key of the player holds, once it holds what's waited for
local function awaitStored(
	fake: FakeDataStoreService,
	key: string,
	timeout: number,
	problem: string,
	getIfDone: (envelope: any) -> boolean
): any
	local startTime = os.clock()
	while true do
		local envelope = fake:Peek(STORE.Name, key) :: any
		if type(envelope) == "table" and getIfDone(envelope) then
			return envelope
		end
		assert(os.clock() - startTime < timeout, problem)
		task.wait()
	end
end

local function getIds(characters: { Character }): { string }
	local out: { string } = {}
	for index, character in characters do
		out[index] = character.Id
	end
	return out
end

-- yields. one player, from before their first visit to their second. it's a single walk because the server has a
-- single player to walk it with. where it stops short: a load that fails ends in a kick + a save is let go of as its
-- player leaves, either one costs the play-test its only player + studio closes a server the last player left
-- before the rest of the specs are through. the data service is held to both without a player, see its spec
local function walk(destroyCallbacks: { () -> () })
	local player = awaitPlayer()
	local userId = player.UserId
	local key = STORE.GetKey(userId)
	local fake = FakeDataStoreUtil.new()
	local function plant<V>(store: ReadOnlyStore<V>, value: unknown)
		fake:Plant(store.Name, store.GetKey(userId), value)
	end

	local furniture = FurnitureDefinition.list()[1]
	local artifact = ItemAppearanceDefinition.list("costume", "artifacts")[1]
	local theme: ThemeDefinition.ThemeDefinition? = nil
	for _, definition in ThemeDefinition.list() do
		if definition.Id ~= ThemeDefinition.DEFAULT_ID then
			theme = definition
			break
		end
	end
	assert(furniture and artifact and theme, `the game is short of furniture, artifacts or themes`)
	local slots: { unknown } = {}
	for index, id in SLOT_IDS do
		local module = StarterSuits:FindFirstChild(`Suit{index}`)
		assert(module and module:IsA("ModuleScript"), `no starter suit {index}`)
		-- required by instance, rojo turns each json into a module
		local suit = require(module) :: any
		slots[index] = { id, suit[1], suit[2] }
	end
	plant(LegacyStoreDefinition.Characters, HttpService:JSONEncode(slots))
	plant(LegacyStoreDefinition.LastCharacterId, SLOT_IDS[LAST_SLOT_INDEX])
	plant(LegacyStoreDefinition.Credits, CREDITS + 0.9)
	plant(LegacyStoreDefinition.Gems, -5)
	-- the mask is the one thing that wasn't left showing under it
	plant(LegacyStoreDefinition.WornArtifact, { artifact.Name :: any, true, false, true, true })
	plant(LegacyStoreDefinition.Furniture, { furniture.Name, theme.Name })
	plant(
		LegacyStoreDefinition.BaseLayout,
		HttpService:JSONEncode({ theme.Name :: any, "a title", { 1 :: any, furniture.Name, PIECE_COMPONENTS } })
	)
	plant(LegacyStoreDefinition.Tutorial, false)
	plant(LegacyStoreDefinition.DailyReward, DAILY_REWARD_AT)

	-- the first visit: a new save, with what the old stores held in place of what it starts out with
	start(destroyCallbacks, fake)
	local session = awaitSession(player)
	local save = session.Save
	assert(save.IsLegacyImported, `the first save wasn't marked as imported`)
	assert(SpecUtil.getIfEqual(getIds(save.Characters), SLOT_IDS), `the old slots didn't make it into the save`)
	assert(save.ActiveCharacterId == SLOT_IDS[LAST_SLOT_INDEX], `the slot that was played last isn't the active one`)
	local appearance = save.Characters[LAST_SLOT_INDEX].Identities.Main.Appearance
	assert(
		save.Characters[LAST_SLOT_INDEX].Identities.Main.Profile.Name == LAST_SLOT_NAME,
		`the name of the hero didn't make it through the filter`
	)
	assert(appearance.Items[#appearance.Items].DefinitionId == artifact.Id, `the hero doesn't wear the artifact`)
	assert(SpecUtil.getIfEqual(appearance.HiddenTags, { "Mask" }), `the artifact hides the wrong items`)
	assert(SpecUtil.getIfEqual(save.Balances, { Credits = CREDITS, Gems = 0 }), `the old balances are off`)
	assert(table.find(save.Inventory.FurnitureIds, furniture.Id), `the old furniture isn't owned`)
	assert(save.BaseLayout.ThemeId == theme.Id and #save.BaseLayout.Furniture == 1, `the old base is off`)
	assert(not save.IsTutorialEnabled and save.LastDailyRewardAt == DAILY_REWARD_AT, `the old settings are off`)
	assert(session.ActiveIdentityKey == "Main" and not session.IsInMenu, `the session didn't start out fresh`)
	assert(
		AttributeDefinition.get(player, AttributeDefinition.ActiveCharacterId) == save.ActiveCharacterId,
		`the player wasn't told their active character`
	)
	local held = fake:Peek(STORE.Name, key) :: any
	assert(type(held) == "table" and type(held.Lock) == "table", `the save of a session isn't locked`)
	assert(held.Data == nil, `the save was written before the autosave got to it`)

	-- an update is with the data service by the time it's made, the autosave writes it without letting go of it
	local isApartmentLocked = not save.IsApartmentLocked
	update(player, function(t: PlayerSave): PlayerSave?
		t.IsApartmentLocked = isApartmentLocked
		return t
	end)
	assert(awaitSession(player).Save.IsApartmentLocked == isApartmentLocked, `the session didn't follow its update`)
	assert(
		AttributeDefinition.get(player, AttributeDefinition.IsApartmentLocked) == isApartmentLocked,
		`the player wasn't told about the update`
	)
	local saved = awaitStored(fake, key, AUTOSAVE_TIMEOUT, `the autosave never wrote the save`, function(envelope: any)
		return envelope.Data ~= nil
	end)
	assert(type(saved.Lock) == "table", `the autosave let go of the save`)
	assert(
		saved.Data.IsApartmentLocked == isApartmentLocked and saved.Data.IsLegacyImported == true,
		`the autosave wrote less than the session holds`
	)

	-- the server closes: the last change is written + the save is let go of
	update(player, function(t: PlayerSave): PlayerSave?
		t.IsTutorialEnabled = true
		return t
	end)
	save = awaitSession(player).Save
	stop(destroyCallbacks)
	local closed = fake:Peek(STORE.Name, key) :: any
	assert(closed.Lock == nil, `the save is still locked after the server closed`)
	assert(closed.Data.IsTutorialEnabled == true, `the last change wasn't written as the server closed`)

	-- the second visit: the save comes back the way it was left + the old stores aren't asked again, they'd hand out
	-- the same thing on top of whatever the player did since
	plant(LegacyStoreDefinition.Credits, CREDITS * 100)
	local callCount = #fake:GetCalls()
	start(destroyCallbacks, fake)
	session = awaitSession(player)
	assert(SpecUtil.getIfEqual(session.Save, save), `the save didn't come back the way it was left`)
	local calls = fake:GetCalls()
	for index = callCount + 1, #calls do
		assert(calls[index].StoreName == STORE.Name, `"{calls[index].StoreName}" was asked for a second import`)
	end
end
-- Class
return SpecUtil.newScenario(function()
	local destroyCallbacks: { () -> () } = {}
	local success, msg = pcall(walk :: any, destroyCallbacks)
	stop(destroyCallbacks)
	if not success then
		error(msg, 0)
	end
end)
