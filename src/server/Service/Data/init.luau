--!strict
-- Services
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
-- Modules
local FakeDataStoreUtil = require("@game/ServerScriptService/Server/Util/FakeDataStore")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
type Store<V> = StoreDefinition.Store<V>
type ReadOnlyStore<V> = StoreDefinition.ReadOnlyStore<V>
type DataStore = FakeDataStoreUtil.DataStore
type DataStoreService = FakeDataStoreUtil.DataStoreService
-- which server holds a document + when it last wrote it, every write renews it
type Lock = {
	ServerId: string,
	At: number,
}
-- what a key of a store holds, the document is in the form the store definition stores it in
type Envelope = {
	Lock: Lock?,
	Data: unknown,
}
type Acquired<V> = {
	Value: V?, -- nil when the key held no document
	Data: unknown,
}
type Loading = {
	IsCanceled: boolean,
}
type Document = {
	Id: string,
	Key: string,
	DataStore: DataStore,
	Pending: unknown, -- what the next write stores
	Revision: number, -- goes up with every value that's handed in
	SavedRevision: number, -- the revision the data store holds
	LockedAt: number,
	IsWriting: boolean,
	IsReleasing: boolean, -- whoever loaded it let go, all that's left of it is the write that takes the lock off
	ReleaseRes: Result<true, string>?, -- nil while that write is on its way
}
type DataServiceImpl = {
	__index: DataServiceImpl,
	Load: <V>(self: DataService, store: Store<V>, userId: number) -> Result<V, string>,
	Save: <V>(self: DataService, store: Store<V>, userId: number, value: V) -> Result<true, string>,
	Release: <V>(self: DataService, store: Store<V>, userId: number) -> Result<true, string>,
	Read: <V>(self: DataService, store: ReadOnlyStore<V>, userId: number) -> Result<Option<V>, string>,
	SetDataStoreService: (self: DataService, dataStoreService: DataStoreService) -> (),
}
export type DataService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_DataStoreService: DataStoreService,
		_Documents: { [string]: Document },
		_Loading: { [string]: Loading },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: DataServiceImpl
))
-- Constants
-- a studio session has no job id, it still has to tell its own lock from the one of another session
local SERVER_ID = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local AUTOSAVE_INTERVAL = 30
-- a document nothing changed in is still written this often, that's what keeps its lock from looking dead
local LOCK_REFRESH_INTERVAL = 60
-- a lock that wasn't renewed for this long belongs to a server that crashed, the next one to ask takes it
local LOCK_TIMEOUT = 300
-- a player who hops between servers can arrive before the last one let go of the save
local LOCK_ATTEMPTS = 5
local LOCK_RETRY_DELAY = 2
local MAX_ATTEMPTS = 4
-- doubles with every attempt
local RETRY_DELAY = 1
-- the engine gives a closing server 30 seconds
local FLUSH_BUDGET = 25
-- a key no user has, reading it is how a studio session finds out if it may use the data stores
local PROBE_KEY = "Probe"
local isEnvelope = Type.strictInterface({
	Lock = Type.optional(Type.strictInterface({
		ServerId = Type.string,
		At = Type.number,
	})),
	Data = Type.optional(Type.table),
})
-- Variables
-- References
-- Private Functions
local function newLock(): Lock
	return {
		ServerId = SERVER_ID,
		At = os.time(),
	}
end

-- the one place the data stores come from: a test hands in the fake it prepared, a place that can't reach the real
-- ones runs on a fake of its own + everything else gets the real ones. yields when it has to ask
local function getDataStoreService(prepared: DataStoreService?): DataStoreService
	if prepared then
		return prepared
	end
	local problem: string? = nil
	if game.GameId == 0 then
		problem = `the place isn't published`
	elseif RunService:IsStudio() then
		-- a session without api access is turned down whatever it asks for, so a read tells as much as a write would
		local success, msg = pcall(function(): unknown
			return (DataStoreService:GetDataStore(StoreDefinition.Player.Name):GetAsync(PROBE_KEY))
		end)
		if not success then
			problem = tostring(msg)
		end
	end
	if problem == nil then
		return DataStoreService :: any
	end
	warn(`saves are kept in memory only: {problem}`)
	return FakeDataStoreUtil.new()
end

-- yields. a data store can fail for no reason of ours, so a call is tried again with a longer wait every time
local function try(call: () -> (), deadline: number?): Result<true, string>
	local msg = ""
	for attempt = 1, MAX_ATTEMPTS do
		-- nothing comes back from the call but what it threw
		local success, res = pcall(call :: any)
		if success then
			return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
		end
		msg = tostring(res)
		local delay = RETRY_DELAY * 2 ^ (attempt - 1)
		if attempt == MAX_ATTEMPTS or (deadline ~= nil and os.clock() + delay > deadline) then
			break
		end
		task.wait(delay)
	end
	return Result.err(msg)
end

local function getDataStore(self: DataService, name: string): Result<DataStore, string>
	-- the real service throws for a place that has no data stores
	local success, res = pcall(function(): DataStore
		return self._DataStoreService:GetDataStore(name)
	end)
	if not success then
		return Result.err(`no "{name}" data store: {res}`)
	end
	return Result.ok(res)
end

-- yields. takes the lock of a key + reads what it holds in one go. the key is left as it is when another server holds
-- it or when what it holds can't be read, so a save that's broken or busy is never written over
local function acquire<V>(
	store: Store<V>,
	dataStore: DataStore,
	key: string,
	loading: Loading
): Result<Acquired<V>, string>
	local value: V? = nil
	local data: unknown = nil
	local problem: string? = nil
	local isHeld = false
	for attempt = 1, LOCK_ATTEMPTS do
		local res = try(function()
			dataStore:UpdateAsync(key, function(current: unknown): unknown
				-- the data store runs this again when the key changed underneath it, only the last run counts
				value, data, problem, isHeld = nil, nil, nil, false
				if current == nil then
					return { Lock = newLock() }
				end
				local success, msg = isEnvelope(current)
				if not success then
					problem = msg
					return nil
				end
				local envelope = current :: Envelope
				local lock = envelope.Lock
				if lock and lock.ServerId ~= SERVER_ID and os.time() - lock.At < LOCK_TIMEOUT then
					isHeld = true
					return nil
				end
				if envelope.Data ~= nil then
					local valueRes = StoreDefinition.decode(store, envelope.Data)
					if valueRes.IsErr then
						problem = valueRes.Value
						return nil
					end
					value, data = valueRes.Value, envelope.Data
				end
				return { Lock = newLock(), Data = envelope.Data }
			end)
		end)
		if res.IsErr then
			return res
		end
		if problem then
			return Result.err(problem)
		end
		if not isHeld then
			return Result.ok({
				Value = value,
				Data = data,
			})
		end
		if loading.IsCanceled or attempt == LOCK_ATTEMPTS then
			break
		end
		task.wait(LOCK_RETRY_DELAY)
	end
	return Result.err(`another server holds it`)
end

-- yields. stores what's pending, as long as the lock in the data store is still ours. a release takes the lock off
local function write(
	documents: { [string]: Document },
	document: Document,
	isRelease: boolean,
	deadline: number?
): Result<true, string>
	-- the autosave + a release can meet, the data store is only ever handed one write of a document at a time
	while document.IsWriting do
		task.wait()
	end
	document.IsWriting = true
	local isLost = false
	local revision = document.Revision
	local res = try(function()
		document.DataStore:UpdateAsync(document.Key, function(current: unknown): unknown
			local lock = if isEnvelope(current) then (current :: Envelope).Lock else nil
			isLost = lock == nil or lock.ServerId ~= SERVER_ID
			if isLost then
				return nil
			end
			revision = document.Revision
			return {
				Lock = if isRelease then nil else newLock(),
				Data = document.Pending,
			}
		end)
	end, deadline)
	document.IsWriting = false
	if res.IsErr then
		return res
	end
	if isLost then
		-- the lock looked dead to another server + it took the document, what's here is behind from now on
		if documents[document.Id] == document then
			documents[document.Id] = nil
		end
		return Result.err(`another server took it over`)
	end
	document.SavedRevision = revision
	document.LockedAt = os.time()
	return res
end

-- yields. a release that fails leaves the document where it is: what's pending is all there is of the last changes, so
-- it's held on to + the release is tried again until the data store takes it
local function release(documents: { [string]: Document }, document: Document, deadline: number?): Result<true, string>
	-- a player who leaves as the server closes is released from both ends, the second one waits for the first
	if document.IsReleasing and document.ReleaseRes == nil then
		while document.ReleaseRes == nil do
			task.wait()
		end
		return document.ReleaseRes :: Result<true, string>
	end
	document.IsReleasing = true
	document.ReleaseRes = nil
	local res = write(documents, document, true, deadline)
	document.ReleaseRes = res
	if res.IsOk and documents[document.Id] == document then
		documents[document.Id] = nil
	end
	return res
end

-- yields
local function load<V>(
	documents: { [string]: Document },
	store: Store<V>,
	dataStore: DataStore,
	id: string,
	key: string,
	loading: Loading
): Result<V, string>
	local acquiredRes = acquire(store, dataStore, key, loading)
	if acquiredRes.IsErr then
		return acquiredRes
	end
	local value, data = acquiredRes.Value.Value, acquiredRes.Value.Data
	local document: Document = {
		Id = id,
		Key = key,
		DataStore = dataStore,
		Pending = data,
		Revision = 0,
		SavedRevision = 0,
		LockedAt = os.time(),
		IsWriting = false,
		IsReleasing = false,
	}
	local problem: string? = nil
	if loading.IsCanceled then
		problem = `it was released while it loaded`
	elseif value == nil or (data :: any).Version ~= store.Version then
		-- a new document + one a migration caught up aren't in the data store yet
		local isMade, default = true, value
		if value == nil then
			-- whatever goes wrong from here on, the lock still has to be handed back
			isMade, default = pcall(store.Default)
		end
		local dataRes = if isMade
			then StoreDefinition.encode(store, default :: V)
			else Result.err(`the default threw: {default}`)
		if dataRes.IsErr then
			problem = dataRes.Value
		else
			value = default
			document.Pending = dataRes.Value
			document.Revision = 1
		end
	end
	if problem or value == nil then
		-- the lock is ours by now, it's handed back with the key holding what it held. the document is kept with the
		-- loaded ones for that, a lock that can't be handed back right away isn't left behind
		documents[id] = document
		release(documents, document)
		return Result.err(`{problem}`)
	end
	documents[id] = document
	return Result.ok(value)
end

local function autosave(self: DataService)
	for _, document in self._Documents do
		if document.IsWriting or (document.IsReleasing and document.ReleaseRes == nil) then
			continue
		end
		local isChanged = document.Revision ~= document.SavedRevision
		if not document.IsReleasing and not isChanged and os.time() - document.LockedAt < LOCK_REFRESH_INTERVAL then
			continue
		end
		task.spawn(function()
			-- a release that didn't get through is still a release
			local res = if document.IsReleasing
				then release(self._Documents, document)
				else write(self._Documents, document, false)
			if res.IsErr then
				warn(`"{document.Id}" wasn't saved: {res.Value}`)
			end
		end)
	end
end

-- yields. everything that's loaded is released, for as long as a closing server is given
local function flush(self: DataService)
	local deadline = os.clock() + FLUSH_BUDGET
	-- a load that's still on its way hands its lock back as soon as it has it
	for _, loading in self._Loading do
		loading.IsCanceled = true
	end
	local releaseCount = 0
	for _, document in self._Documents do
		releaseCount += 1
		task.spawn(function()
			local res = release(self._Documents, document, deadline)
			if res.IsErr then
				warn(`"{document.Id}" wasn't saved: {res.Value}`)
			end
			releaseCount -= 1
		end)
	end
	while (releaseCount > 0 or next(self._Loading) ~= nil) and os.clock() < deadline do
		task.wait()
	end
end
-- Class
local DataService = {} :: DataServiceImpl
DataService.__index = DataService

-- yields. the document is locked to this server until it's released, an error means nothing was loaded + whatever the
-- data store holds was left alone. a user who was never saved gets the default of the store
function DataService:Load<V>(store: Store<V>, userId: number): Result<V, string>
	local key = store.GetKey(userId)
	local id = `{store.Name}/{key}`
	-- a caller reaches the service through its locker, which lets go the moment the service is destroyed. the tables
	-- are held on to so that a call that's still out by then can tidy up after itself
	local documents, loadings = self._Documents, self._Loading
	-- a player can be back before their last visit is through: a load they left in the middle of is waited out
	while loadings[id] and loadings[id].IsCanceled do
		task.wait()
	end
	-- + what they had is written before it's read again. if that can't be done the data store is behind on them, a
	-- load would hand out less than they left with
	local prior = documents[id]
	if prior and prior.IsReleasing then
		local releaseRes = release(documents, prior)
		if documents[id] == prior then
			return Result.err(`"{id}" wasn't loaded: the last changes to it aren't saved: {releaseRes.Value}`)
		end
	end
	if not self.IsInitialized then
		return Result.err(`the data service isn't initialized`)
	end
	if documents[id] or loadings[id] then
		return Result.err(`"{id}" is already loaded`)
	end
	local dataStoreRes = getDataStore(self, store.Name)
	if dataStoreRes.IsErr then
		return dataStoreRes
	end
	local loading: Loading = {
		IsCanceled = false,
	}
	loadings[id] = loading
	local res = load(documents, store, dataStoreRes.Value, id, key, loading)
	loadings[id] = nil
	if res.IsErr then
		return Result.err(`"{id}" wasn't loaded: {res.Value}`)
	end
	return res
end

-- doesn't yield + doesn't write. the value is checked + kept as what the next write stores, the autosave + the release
-- do the writing. whoever owns a document hands it in every time it changes, there's nothing else to call
function DataService:Save<V>(store: Store<V>, userId: number, value: V): Result<true, string>
	local id = `{store.Name}/{store.GetKey(userId)}`
	local document = self._Documents[id]
	-- a save that wasn't read can't be told from one that isn't there, writing it would wipe what the player had
	if not document or document.IsReleasing then
		return Result.err(`"{id}" isn't loaded`)
	end
	local dataRes = StoreDefinition.encode(store, value)
	if dataRes.IsErr then
		return Result.err(`bad "{id}" value: {dataRes.Value}`)
	end
	document.Pending = dataRes.Value
	document.Revision += 1
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- yields. writes what's pending + takes the lock off. an error means the last changes didn't make it yet, they're
-- written again with every autosave + as the server closes
function DataService:Release<V>(store: Store<V>, userId: number): Result<true, string>
	local id = `{store.Name}/{store.GetKey(userId)}`
	local loading = self._Loading[id]
	if loading then
		loading.IsCanceled = true
	end
	local document = self._Documents[id]
	if not document then
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	return release(self._Documents, document)
end

-- yields. a key that holds nothing isn't an error, there's just nothing there
function DataService:Read<V>(store: ReadOnlyStore<V>, userId: number): Result<Option<V>, string>
	local key = store.GetKey(userId)
	local id = `{store.Name}/{key}`
	local dataStoreRes = getDataStore(self, store.Name)
	if dataStoreRes.IsErr then
		return dataStoreRes
	end
	local value: unknown = nil
	local res = try(function()
		value = dataStoreRes.Value:GetAsync(key)
	end)
	if res.IsErr then
		return Result.err(`"{id}" wasn't read: {res.Value}`)
	end
	if value == nil then
		return Result.ok(Option.none())
	end
	local success, msg = store.Validator(value)
	if not success then
		return Result.err(`bad "{id}" value: {msg}`)
	end
	if type(value) == "table" then
		TableUtil.deepFreeze(value :: any)
	end
	return Result.ok(Option.some(value :: any))
end

-- for a test: it hands in the fake it prepared, before anything is loaded
function DataService:SetDataStoreService(dataStoreService: DataStoreService)
	assert(next(self._Documents) == nil and next(self._Loading) == nil, `a document is loaded`)
	self._DataStoreService = getDataStoreService(dataStoreService)
end

return ServiceLocker(function(): DataService
	local self = setmetatable({
		IsInitialized = true :: true,
		_DataStoreService = getDataStoreService(nil),
		_Documents = {},
		_Loading = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, DataService)

	local autosaveThread = task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			autosave(self)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		task.cancel(autosaveThread)
	end)

	return self
end, function(self: DataService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	-- the server destroys its services as it closes, which is the last moment a save can be written. the close is
	-- held up until that's done
	flush(self)
	table.clear(self :: any)
end)
