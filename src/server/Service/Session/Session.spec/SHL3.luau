--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FakeDataStoreUtil = require("@game/ServerScriptService/Server/Util/FakeDataStore")
local LegacyImportService = require("@game/ServerScriptService/Server/Service/LegacyImport")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type PlayerSave = SaveType.PlayerSave
type Session = SessionService.Session
type FakeDataStoreService = FakeDataStoreUtil.FakeDataStoreService
-- Constants
local STORE = StoreDefinition.Player
-- a session takes a player + the server has no way to make one up, so the walk waits for whoever play-tests
local PLAYER_TIMEOUT = 30
local SESSION_TIMEOUT = 30
-- Variables
-- References
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

-- every call the fake took was for the store of the game itself: there's no game before it whose stores could be asked
local function assertOwnStoreOnly(fake: FakeDataStoreService)
	for _, call in fake:GetCalls() do
		assert(call.StoreName == STORE.Name, `"{call.StoreName}" was asked, the game has nothing to import from`)
	end
end

-- yields. one player, from before their first visit to their second. it's a single walk because the server has a
-- single player to walk it with. the game has no importer yet, so what the walk holds the session to is that a save
-- is never marked as imported along the way: the day the importer is there every save of before is still due
local function walk(destroyCallbacks: { () -> () })
	local player = awaitPlayer()
	local key = STORE.GetKey(player.UserId)
	local fake = FakeDataStoreUtil.new()

	-- the first visit: a new save, the way the game starts a player out
	start(destroyCallbacks, fake)
	assert(
		LegacyImportService.IsInitialized and not LegacyImportService.HasImporter,
		`the game has an importer, this spec is out of date`
	)
	local session = awaitSession(player)
	local save = session.Save
	assert(not save.IsLegacyImported, `a save was marked as imported with no game to import from`)
	assert(
		#save.Characters == ProductDefinition.getCharacterSlotCount({}),
		`a new player has {#save.Characters} characters`
	)
	assert(save.ActiveCharacterId == save.Characters[1].Id, `the first character isn't the active one`)
	assert(SpecUtil.getIfEqual(save.Balances, ProductDefinition.STARTING_BALANCES), `the starting balances are off`)
	assert(session.ActiveIdentityKey == "Main" and not session.IsInMenu, `the session didn't start out fresh`)
	assert(
		AttributeDefinition.get(player, AttributeDefinition.ActiveCharacterId) == save.ActiveCharacterId,
		`the player wasn't told their active character`
	)
	assertOwnStoreOnly(fake)
	local held = fake:Peek(STORE.Name, key) :: any
	assert(type(held) == "table" and type(held.Lock) == "table", `the save of a session isn't locked`)

	-- an update is with the data service by the time it's made
	local nextCharacterId = save.Characters[2].Id
	update(player, function(t: PlayerSave): PlayerSave?
		t.ActiveCharacterId = nextCharacterId
		return t
	end)
	save = awaitSession(player).Save
	assert(save.ActiveCharacterId == nextCharacterId, `the session didn't follow its update`)
	assert(
		AttributeDefinition.get(player, AttributeDefinition.ActiveCharacterId) == nextCharacterId,
		`the player wasn't told about the update`
	)

	-- the server closes: the change is written + the save is let go of, still unmarked
	stop(destroyCallbacks)
	local closed = fake:Peek(STORE.Name, key) :: any
	assert(closed.Lock == nil, `the save is still locked after the server closed`)
	assert(closed.Data.ActiveCharacterId == nextCharacterId, `the change wasn't written as the server closed`)
	assert(closed.Data.IsLegacyImported == false, `the save was written as imported`)

	-- the second visit: the save comes back the way it was left
	start(destroyCallbacks, fake)
	session = awaitSession(player)
	assert(SpecUtil.getIfEqual(session.Save, save), `the save didn't come back the way it was left`)
	assert(not session.Save.IsLegacyImported, `the second visit marked the save as imported`)
	assertOwnStoreOnly(fake)
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
