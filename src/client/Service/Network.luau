--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type ClientEvent<T> = RemoteDefinition.ClientEvent<T>
type ServerEvent<T> = RemoteDefinition.ServerEvent<T>
type ClientFunction<V, T> = RemoteDefinition.ClientFunction<V, T>
type NetworkServiceImpl = {
	__index: NetworkServiceImpl,
	Fire: <T>(self: NetworkService, remote: ClientEvent<T>, value: T) -> (),
	Invoke: <V, T>(self: NetworkService, remote: ClientFunction<V, T>, value: T) -> Result<V, string>,
	Connect: <T>(self: NetworkService, remote: ServerEvent<T>, handler: (value: T) -> ()) -> RBXScriptConnection,
}
export type NetworkService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Events: { [string]: RemoteEvent },
		_Functions: { [string]: RemoteFunction },
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
-- Class
local NetworkService = {} :: NetworkServiceImpl
NetworkService.__index = NetworkService

function NetworkService:Fire<T>(remote: ClientEvent<T>, value: T)
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Events[remote.Name]
	assert(inst and remote.Direction == "ClientToServer", `"{remote.Name}" isn't an event clients fire`)
	local success, msg = remote.Argument(value)
	if not success then
		warn(`can't fire "{remote.Name}": {msg}`)
		return
	end
	inst:FireServer(value)
end

-- yields until the server answered, call from task.spawn wherever the caller can't wait
function NetworkService:Invoke<V, T>(remote: ClientFunction<V, T>, value: T): Result<V, string>
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Functions[remote.Name]
	assert(inst, `"{remote.Name}" isn't a function clients invoke`)
	local success, msg = remote.Argument(value)
	if not success then
		warn(`can't invoke "{remote.Name}": {msg}`)
		return Result.err(`invalid request`)
	end
	local isDone, res = pcall(function(): unknown
		return inst:InvokeServer(value)
	end)
	if not isDone then
		warn(`"{remote.Name}" failed: {res}`)
		return Result.err(`no answer from the server`)
	end
	local isResult, resultMsg = remote.Returns(res)
	if not isResult then
		warn(`"{remote.Name}" answered with a bad result: {resultMsg}`)
		return Result.err(`no answer from the server`)
	end
	-- rebuilt so the caller holds a frozen Result like any other
	local answer = res :: Result<V, string>
	if answer.IsErr then
		return Result.err(answer.Value)
	end
	freeze(answer.Value)
	return Result.ok(answer.Value)
end

function NetworkService:Connect<T>(remote: ServerEvent<T>, handler: (value: T) -> ()): RBXScriptConnection
	assert(self.IsInitialized, `the network service isn't initialized`)
	local inst = self._Events[remote.Name]
	assert(inst and remote.Direction == "ServerToClient", `"{remote.Name}" isn't an event the server fires`)
	local connection = inst.OnClientEvent:Connect(function(value: unknown)
		local success, msg = remote.Argument(value)
		if not success then
			warn(`dropped "{remote.Name}": {msg}`)
			return
		end
		freeze(value)
		handler(value :: any)
	end)
	-- menus connect + disconnect over and over, so the dead ones make room as new ones come in
	for i = #self._Connections, 1, -1 do
		if not self._Connections[i].Connected then
			table.remove(self._Connections, i)
		end
	end
	table.insert(self._Connections, connection)
	return connection
end

return ServiceLocker(function(): NetworkService
	-- the server makes the remotes as it starts, so this yields until they have replicated
	local folder = IndexUtil.waitForLocalPath(ReplicatedStorage, RemoteDefinition.FOLDER_NAME)
	local events: { [string]: RemoteEvent } = {}
	local functions: { [string]: RemoteFunction } = {}
	for _, remote in RemoteDefinition.list() do
		local inst = IndexUtil.waitForLocalPath(folder, remote.Name)
		if remote.Kind == "Event" then
			assert(inst:IsA("RemoteEvent"), `"{remote.Name}" isn't a RemoteEvent`)
			events[remote.Name] = inst
		else
			assert(inst:IsA("RemoteFunction"), `"{remote.Name}" isn't a RemoteFunction`)
			functions[remote.Name] = inst
		end
	end

	local self = setmetatable({
		IsInitialized = true :: true,
		_Events = events,
		_Functions = functions,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, NetworkService)
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
