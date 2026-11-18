--!strict
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
local ServerRegistryUtil = require("@game/ServerScriptService/Server/Util/ServerRegistry")
local TextFilterUtil = require("@game/ServerScriptService/Server/Util/TextFilter")
-- Types
local RegistryType = require("@game/ServerScriptService/Server/Type/Registry")
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
type Result<V, E> = TypeUnionLib.Result<V, E>
type ClientFunction<V, T> = RemoteDefinition.ClientFunction<V, T>
type CustomServer = RegistryType.CustomServer
type Mode = ServerType.Mode
type Listing = ServerType.Listing
type Settings = ServerType.Settings
type Entry = ServerType.Entry
-- what the map of custom servers held when it was last read
type ListCache = {
	Res: Result<{ CustomServer }, string>?,
	ReadAt: number, -- on the clock of os.clock
	IsReading: boolean,
}
type ModeSelectServiceImpl = {
	__index: ModeSelectServiceImpl,
}
export type ModeSelectService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_ListCache: ListCache,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ModeSelectServiceImpl
))
-- Constants
local IS_STUDIO = RunService:IsStudio()
-- a server somebody bought for themselves has an owner the engine knows, a custom one doesn't
local IS_RESERVED = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
local TELEPORT_ATTEMPTS = 3
local TELEPORT_RETRY_DELAY = 1
-- a crowd pressing refresh is answered out of one read
local LIST_LIFETIME = 5
-- a server that was just made has this long to boot + take over its record
local BOOT_EXPIRY = 120
local FILTER_TIMEOUT = 5
-- every text below ends up in front of a player as it is
local DISABLED_TEXT = `not available on this server`
local REGISTRY_TEXT = `can't reach the server list, try again`
local TELEPORT_TEXT = if IS_STUDIO then `can't teleport from studio` else `the teleport failed, try again`
local SAME_SERVER_TEXT = `you're already on that server`
local FAILURE_TEXTS: { [Enum.TeleportResult]: string } = table.freeze({
	[Enum.TeleportResult.GameNotFound] = `that server couldn't be found`,
	[Enum.TeleportResult.GameEnded] = `that server has closed`,
	[Enum.TeleportResult.GameFull] = `that server is full`,
	[Enum.TeleportResult.Unauthorized] = `you aren't allowed into that server`,
	[Enum.TeleportResult.Flooded] = `too many teleports at once, try again in a moment`,
	[Enum.TeleportResult.IsTeleporting] = `a teleport is already on its way`,
})
-- Variables
-- References
-- Private Functions
-- a mode is a place: the one this build runs in, or the one the build was told about. 0 when it wasn't told
local function getPlaceId(mode: Mode): number
	if mode == BUILD_CONFIG.MODE then
		return game.PlaceId
	end
	return if mode == "roleplay" then BUILD_CONFIG.ROLEPLAY_PLACE_ID else 0
end

-- whoever the game sent here picked their mode on the way: into a custom server, or over from another of its places
local function getIfModeChosen(player: Player): boolean
	if IS_RESERVED then
		return true
	end
	-- a place that isn't published has no game anybody could come from
	return game.GameId ~= 0 and player:GetJoinData().SourceGameId == game.GameId
end

-- yields. ok means the teleport is on its way, it can still fall over after that
local function teleport(player: Player, placeId: number, options: TeleportOptions?): Result<true, string>
	local msg = ""
	for attempt = 1, TELEPORT_ATTEMPTS do
		local success, res = pcall(function()
			TeleportService:TeleportAsync(placeId, { player }, options)
		end)
		if success then
			return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
		end
		msg = tostring(res)
		-- a studio session that can't teleport doesn't learn to by the next try
		if IS_STUDIO or attempt == TELEPORT_ATTEMPTS or not player:IsDescendantOf(Players) then
			break
		end
		task.wait(TELEPORT_RETRY_DELAY)
	end
	warn(`{player.Name} wasn't teleported to {placeId}: {msg}`)
	return Result.err(TELEPORT_TEXT)
end

local function filter(player: Player, text: string): Result<string, string>
	local f = Future.timeout(TextFilterUtil.filter(text, player.UserId), FILTER_TIMEOUT)
	if f.IsCanceled then
		return Result.err(`the filter took too long`)
	end
	return f.Value
end

-- yields. the map is only read when somebody asks for it + whoever asks while a read is out waits for that one
local function list(cache: ListCache): Result<{ CustomServer }, string>
	while cache.IsReading do
		task.wait()
	end
	if cache.Res and os.clock() - cache.ReadAt < LIST_LIFETIME then
		return cache.Res
	end
	cache.IsReading = true
	local res = ServerRegistryUtil.listCustomServers()
	cache.Res = res
	cache.ReadAt = os.clock()
	cache.IsReading = false
	if res.IsErr then
		warn(`server list err: {res.Value}`)
	end
	return res
end

local function selectMode(player: Player, mode: Mode): Result<true, string>
	if mode == BUILD_CONFIG.MODE then
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	local placeId = getPlaceId(mode)
	if placeId == 0 then
		return Result.err(`{mode} isn't available yet`)
	end
	return teleport(player, placeId, nil)
end

local function joinServerById(player: Player, text: string): Result<true, string>
	-- typed in by hand, so it comes with spaces around it + in whatever case
	local id = ServerDefinition.getId(string.match(text, "^%s*(.-)%s*$") or "")
	local serverRes = ServerRegistryUtil.getPublicServer(id)
	if serverRes.IsErr then
		warn(`server id err: {serverRes.Value}`)
		return Result.err(REGISTRY_TEXT)
	end
	if serverRes.Value.IsNone then
		return Result.err(`no server has that id`)
	end
	local server = serverRes.Value.Value
	if server.JobId == game.JobId then
		return Result.err(SAME_SERVER_TEXT)
	end
	local options = Instance.new("TeleportOptions")
	options.ServerInstanceId = server.JobId
	return teleport(player, server.PlaceId, options)
end

local function getServers(cache: ListCache, player: Player): Result<{ Listing }, string>
	local serversRes = list(cache)
	if serversRes.IsErr then
		return Result.err(REGISTRY_TEXT)
	end
	local region = ServerDefinition.getRegion(player.LocaleId)
	local scores: { [Listing]: number } = {}
	local out: { Listing } = {}
	for _, server in serversRes.Value do
		local score = ServerRegistryUtil.getScore(server, player.UserId, region)
		if score <= 0 then
			continue
		end
		local listing = ServerRegistryUtil.newListing(server)
		scores[listing] = score
		table.insert(out, listing)
	end
	table.sort(out, function(a: Listing, b: Listing): boolean
		if scores[a] ~= scores[b] then
			return scores[a] > scores[b]
		end
		-- servers that score the same don't swap rows from one refresh to the next
		return a.Id < b.Id
	end)
	return Result.ok(out)
end

local function createServer(player: Player, settings: Settings): Result<true, string>
	local fixedSettings = ServerDefinition.fixSettings(settings)
	-- every custom server is a server of the one place that's built for them, whichever way its owner wants it played
	local placeId = BUILD_CONFIG.PRIVATE_SERVER_PLACE_ID
	if placeId == 0 then
		return Result.err(`custom servers aren't available yet`)
	end
	local nameRes = filter(player, fixedSettings.Name)
	if nameRes.IsErr then
		warn(`server name of {player.Name} wasn't filtered: {nameRes.Value}`)
		return Result.err(`that name can't be checked right now, try again`)
	end
	-- a server is reserved by the first teleport that's aimed at an id nobody used before
	local server: CustomServer = {
		Id = HttpService:GenerateGUID(false),
		PlaceId = placeId,
		OwnerId = player.UserId,
		OwnerName = player.Name,
		Name = nameRes.Value,
		Code = fixedSettings.Code,
		IsPVP = fixedSettings.IsPVP,
		Region = ServerDefinition.getRegion(player.LocaleId),
		Limit = fixedSettings.Limit,
		Fill = 0,
		AdminIds = {},
		BannedIds = {},
	}
	-- the record is there before the server is, it's the first thing the server asks for
	local setRes = ServerRegistryUtil.setCustomServer(server, BOOT_EXPIRY)
	if setRes.IsErr then
		warn(`custom server of {player.Name} wasn't made: {setRes.Value}`)
		return Result.err(`can't set up a server right now, try again`)
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerId = server.Id
	local teleportRes = teleport(player, placeId, options)
	if teleportRes.IsErr then
		-- nobody is on their way to it
		ServerRegistryUtil.removeCustomServer(server.Id)
	end
	return teleportRes
end

local function joinServer(player: Player, entry: Entry): Result<true, string>
	-- the list a client picked from can be a while old, what counts is what the server says of itself right now
	local serverRes = ServerRegistryUtil.getCustomServer(entry.Id)
	if serverRes.IsErr then
		warn(`custom server err: {serverRes.Value}`)
		return Result.err(REGISTRY_TEXT)
	end
	if serverRes.Value.IsNone then
		return Result.err(`that server is gone`)
	end
	local server = serverRes.Value.Value
	if server.Id == game.PrivateServerId then
		return Result.err(SAME_SERVER_TEXT)
	elseif table.find(server.BannedIds, player.UserId) then
		return Result.err(`you're banned from that server`)
	elseif server.Fill >= server.Limit then
		return Result.err(`that server is full`)
	elseif server.Code ~= "" and entry.Code ~= server.Code then
		-- the browser writes this into the box the code was typed in
		return Result.err(`incorrect`)
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerId = server.Id
	return teleport(player, server.PlaceId, options)
end

-- a function nobody handles keeps its caller waiting for good, so on a build without the mode screen every one of
-- them still answers
local function handle<V, T>(remote: ClientFunction<V, T>, handler: (player: Player, value: T) -> Result<V, string>)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	NetworkService:Handle(remote, function(player: Player, value: T): Result<V, string>
		if not BUILD_CONFIG.MODE_SELECT_ENABLED then
			return Result.err(DISABLED_TEXT)
		end
		return handler(player, value)
	end)
end
-- Class
local ModeSelectService = {} :: ModeSelectServiceImpl
ModeSelectService.__index = ModeSelectService

return ServiceLocker(function(): ModeSelectService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_ListCache = {
			ReadAt = 0,
			IsReading = false,
		} :: ListCache,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ModeSelectService)

	-- held on to, a call that's still out when the service is destroyed finishes on it
	local listCache = self._ListCache
	handle(RemoteDefinition.SelectMode, selectMode)
	handle(RemoteDefinition.JoinServerById, joinServerById)
	handle(RemoteDefinition.CreateServer, createServer)
	handle(RemoteDefinition.JoinServer, joinServer)
	handle(RemoteDefinition.GetServers, function(player: Player): Result<{ Listing }, string>
		return getServers(listCache, player)
	end)

	-- the screen that sent a player off is waiting for them to leave, it's told when they won't
	table.insert(
		self._Connections,
		TeleportService.TeleportInitFailed:Connect(function(player: Player, teleportResult: Enum.TeleportResult)
			assert(NetworkService.IsInitialized, `the network service isn't initialized`)
			local text = FAILURE_TEXTS[teleportResult] or TELEPORT_TEXT
			NetworkService:Fire(RemoteDefinition.TeleportFailed, player, text)
		end)
	)

	table.insert(
		self._Connections,
		Players.PlayerAdded:Connect(function(player: Player)
			AttributeDefinition.set(player, AttributeDefinition.IsModeChosen, getIfModeChosen(player))
		end)
	)
	for _, player in Players:GetPlayers() do
		AttributeDefinition.set(player, AttributeDefinition.IsModeChosen, getIfModeChosen(player))
	end

	return self
end, function(self: ModeSelectService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
