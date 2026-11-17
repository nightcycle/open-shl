--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V> = SessionType.Result<V>
type RateLimit = RemoteDefinition.RateLimit
type ClientEvent<T> = RemoteDefinition.ClientEvent<T>
type ServerEvent<T> = RemoteDefinition.ServerEvent<T>
type ClientFunction<V, T> = RemoteDefinition.ClientFunction<V, T>
-- how many calls of a remote a player made since the stretch its rate limit counts over began
type Usage = {
	StartTime: number, -- on the clock of os.clock
	Count: number,
}
type NetworkServiceImpl = {
	__index: NetworkServiceImpl,
	Connect: <T>(
		self: NetworkService,
		remote: ClientEvent<T>,
		handler: (player: Player, value: T) -> ()
	) -> RBXScriptConnection,
	Handle: <V, T>(
		self: NetworkService,
		remote: ClientFunction<V, T>,
		handler: (player: Player, value: T) -> Result<V>
	) -> (),
	Fire: <T>(self: NetworkService, remote: ServerEvent<T>, player: Player, value: T) -> (),
	FireAll: <T>(self: NetworkService, remote: ServerEvent<T>, value: T) -> (),
}
export type NetworkService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Events: { [string]: RemoteEvent },
		_Functions: { [string]: RemoteFunction },
		_IsHandled: { [string]: true },
		_Usages: { [Player]: { [string]: Usage } },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: NetworkServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- a table that came through a remote is a copy nobody else holds, so it's frozen where it lands
local function freeze(value: unknown)
	if type(value) == "table" then
		TableUtil.deepFreeze(value :: any)
	end
end

-- counts a call, whatever it carries + whatever becomes of it. answers if the player still had one left
local function use(self: NetworkService, player: Player, name: string, rateLimit: RateLimit): boolean
	local usages = self._Usages[player]
	if not usages then
		usages = {}
		self._Usages[player] = usages
	end
	local priorUsage = usages[name]
	local usage: Usage = if priorUsage and os.clock() - priorUsage.StartTime < rateLimit.Duration
		then priorUsage
		else {
			StartTime = os.clock(),
			Count = 0,
		}
	usages[name] = usage
	usage.Count += 1
	-- a flood is told about once, not with every call of it
	if usage.Count == rateLimit.Count + 1 then
		warn(`{player.Name} is over the rate limit of "{name}"`)
	end
	return usage.Count <= rateLimit.Count
end
-- Class
local NetworkService = {} :: NetworkServiceImpl
NetworkService.__index = NetworkService

-- the handler only ever runs with a value that passed the validator of the remote, anything else is dropped. so is
-- whatever comes in faster than the rate limit of the remote allows
function NetworkService:Connect<T>(remote: ClientEvent<T>, handler: (Player, T) -> ()): RBXScriptConnection
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Events[remote.Name]
	assert(inst and remote.Direction == "ClientToServer", `"{remote.Name}" isn't an event clients fire`)
	local connection = inst.OnServerEvent:Connect(function(player: Player, value: unknown)
		if not use(self, player, remote.Name, remote.RateLimit) then
			return
		end
		local success, msg = remote.Argument(value)
		if not success then
			warn(`dropped "{remote.Name}" from {player.Name}: {msg}`)
			return
		end
		freeze(value)
		handler(player, value :: any)
	end)
	return connection
end

-- a function has a single handler, it may yield + whatever happens the client gets a Result back
function NetworkService:Handle<V, T>(remote: ClientFunction<V, T>, handler: (Player, T) -> Result<V>)
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Functions[remote.Name]
	assert(inst, `"{remote.Name}" isn't a function clients invoke`)
	assert(not self._IsHandled[remote.Name], `"{remote.Name}" already has a handler`)
	self._IsHandled[remote.Name] = true
	-- who has a call of an exclusive function going
	local isBusy: { [Player]: true? } = {}
	inst.OnServerInvoke = function(player: Player, value: unknown): Result<V>
		if not use(self, player, remote.Name, remote.RateLimit) then
			return Result.err(`too many requests`)
		end
		local success, msg = remote.Argument(value)
		if not success then
			warn(`dropped "{remote.Name}" from {player.Name}: {msg}`)
			return Result.err(`invalid request`)
		end
		if isBusy[player] then
			return Result.err(`the last request isn't done yet`)
		end
		isBusy[player] = if remote.IsExclusive then true else nil
		freeze(value)
		local isDone, res = xpcall(handler :: any, debug.traceback, player, value)
		isBusy[player] = nil
		if not isDone then
			warn(`"{remote.Name}" handler failed: {res}`)
			return Result.err(`server error`)
		end
		local isResult, resultMsg = remote.Returns(res)
		if not isResult then
			warn(`"{remote.Name}" handler returned a bad result: {resultMsg}`)
			return Result.err(`server error`)
		end
		return res
	end
end

function NetworkService:Fire<T>(remote: ServerEvent<T>, player: Player, value: T)
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Events[remote.Name]
	assert(inst and remote.Direction == "ServerToClient", `"{remote.Name}" isn't an event the server fires`)
	local success, msg = remote.Argument(value)
	if not success then
		error(`can't fire "{remote.Name}": {msg}`)
	end
	inst:FireClient(player, value)
end

function NetworkService:FireAll<T>(remote: ServerEvent<T>, value: T)
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Events[remote.Name]
	assert(inst and remote.Direction == "ServerToClient", `"{remote.Name}" isn't an event the server fires`)
	local success, msg = remote.Argument(value)
	if not success then
		error(`can't fire "{remote.Name}": {msg}`)
	end
	inst:FireAllClients(value)
end

return ServiceLocker(function(): NetworkService
	local folder = Instance.new("Folder")
	folder.Name = RemoteDefinition.FOLDER_NAME
	local events: { [string]: RemoteEvent } = {}
	local functions: { [string]: RemoteFunction } = {}
	for _, remote in RemoteDefinition.list() do
		if remote.Kind == "Event" then
			local inst = Instance.new("RemoteEvent")
			inst.Name = remote.Name
			inst.Parent = folder
			events[remote.Name] = inst
		else
			local inst = Instance.new("RemoteFunction")
			inst.Name = remote.Name
			inst.Parent = folder
			functions[remote.Name] = inst
		end
	end
	-- parented last so a client never finds the folder half filled
	folder.Parent = ReplicatedStorage

	local self = setmetatable({
		IsInitialized = true :: true,
		_Events = events,
		_Functions = functions,
		_IsHandled = {},
		_Usages = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, NetworkService)

	-- nothing listens to the events only the server fires, so whatever a client pushes into one would pile up in its
	-- queue. it's taken out right away + dropped instead
	for _, remote in RemoteDefinition.list() do
		if remote.Kind == "Event" and remote.Direction == "ServerToClient" then
			table.insert(self._Connections, events[remote.Name].OnServerEvent:Connect(function() end))
		end
	end

	table.insert(
		self._Connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			self._Usages[player] = nil
		end)
	)

	table.insert(self._CleanUpCallbacks, function()
		folder:Destroy()
	end)

	return self
end, function(self: NetworkService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
