--!strict
-- Services
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ServerRegistryUtil = require("@game/ServerScriptService/Server/Util/ServerRegistry")
-- Types
local RegistryType = require("@game/ServerScriptService/Server/Type/Registry")
type Result<V, E> = TypeUnionLib.Result<V, E>
type CustomServer = RegistryType.CustomServer
-- what the owner or an admin types into the chat, followed by a user name
type Command = {
	Name: string,
	Alias: string,
	List: "Admin" | "Banned",
	IsAdded: boolean, -- if it puts the user on the list or takes them off it
	IsOwnerOnly: boolean,
}
type CustomServerServiceImpl = {
	__index: CustomServerServiceImpl,
}
export type CustomServerService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- nil on a server that isn't a custom one + on one whose record is gone, that one runs unlisted
		_Server: CustomServer?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: CustomServerServiceImpl
))
-- Constants
-- a server somebody bought for themselves has an owner the engine knows, a custom one doesn't
local IS_RESERVED = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
local HEARTBEAT_INTERVAL = 15
-- a server that crashed drops out of the browser after this long
local EXPIRY = 60
local READ_ATTEMPTS = 3
local READ_RETRY_DELAY = 2
local BAN_MESSAGE = `You have been banned from this private server`
local COMMANDS: { Command } = table.freeze({
	{ Name = "Ban", Alias = "/ban", List = "Banned", IsAdded = true, IsOwnerOnly = false } :: Command,
	{ Name = "Unban", Alias = "/unban", List = "Banned", IsAdded = false, IsOwnerOnly = false },
	-- an admin who could make admins could hand the server to anybody
	{ Name = "Admin", Alias = "/admin", List = "Admin", IsAdded = true, IsOwnerOnly = true },
	{ Name = "Unadmin", Alias = "/unadmin", List = "Admin", IsAdded = false, IsOwnerOnly = true },
})
-- Variables
-- References
-- Private Functions
-- yields. a record that can't be read is asked for again, one that's gone stays gone
local function load(): Result<CustomServer, string>
	local msg = ""
	for attempt = 1, READ_ATTEMPTS do
		local serverRes = ServerRegistryUtil.getCustomServer(game.PrivateServerId)
		if serverRes.IsOk then
			if serverRes.Value.IsSome then
				return Result.ok(serverRes.Value.Value)
			end
			return Result.err(`"{game.PrivateServerId}" has no record`)
		end
		msg = serverRes.Value
		if attempt < READ_ATTEMPTS then
			task.wait(READ_RETRY_DELAY)
		end
	end
	return Result.err(msg)
end

-- yields. the head count is taken as the record goes out, it's kept nowhere else
local function write(server: CustomServer): Result<true, string>
	local out = table.clone(server)
	out.Fill = #Players:GetPlayers()
	return ServerRegistryUtil.setCustomServer(out, EXPIRY)
end

local function kickIfBanned(server: CustomServer, player: Player)
	if table.find(server.BannedIds, player.UserId) then
		player:Kick(BAN_MESSAGE)
	end
end

local function getList(server: CustomServer, list: "Admin" | "Banned"): { number }
	return if list == "Admin" then server.AdminIds else server.BannedIds
end

local function getIfAllowed(server: CustomServer, command: Command, userId: number): boolean
	if userId == server.OwnerId then
		return true
	end
	return not command.IsOwnerOnly and table.find(server.AdminIds, userId) ~= nil
end

-- yields. the user name is looked up on the web, whatever the record says is read again once that's back
local function execute(self: CustomServerService, command: Command, speakerId: number, message: string)
	local server = self._Server
	local userName = string.match(message, "^%S+%s+(%S+)")
	if not server or not userName or not getIfAllowed(server, command, speakerId) then
		return
	end
	local success, res = pcall(function(): number
		return Players:GetUserIdFromNameAsync(userName)
	end)
	if not success then
		warn(`"{command.Alias} {userName}" err: {res}`)
		return
	end
	local userId: number = res
	server = self._Server
	-- no command does anything to the owner
	if not server or userId == server.OwnerId or not getIfAllowed(server, command, speakerId) then
		return
	end
	local newServer = FreezeUtil.delta(server, function(t: CustomServer): CustomServer?
		local list = getList(t, command.List)
		local index = table.find(list, userId)
		if command.IsAdded and not index then
			table.insert(list, userId)
		elseif not command.IsAdded and index then
			table.remove(list, index)
		else
			return nil
		end
		return t
	end)
	if newServer == server then
		return
	end
	self._Server = newServer
	if command.List == "Banned" and command.IsAdded then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			player:Kick(BAN_MESSAGE)
		end
	end
	-- the next heartbeat would carry it too, until then the browser would still let somebody who's banned in
	local writeRes = write(newServer)
	if writeRes.IsErr then
		warn(`custom server err: {writeRes.Value}`)
	end
end

-- yields for as long as the service lives
local function run(self: CustomServerService)
	local isFailing = false
	while true do
		local server = self._Server
		if not server then
			return
		end
		local writeRes = write(server)
		-- a memory store that's down is told about once, not with every heartbeat it turns down
		if writeRes.IsErr and not isFailing then
			warn(`custom server err: {writeRes.Value}`)
		end
		isFailing = writeRes.IsErr
		task.wait(HEARTBEAT_INTERVAL)
	end
end
-- Class
local CustomServerService = {} :: CustomServerServiceImpl
CustomServerService.__index = CustomServerService

return ServiceLocker(function(): CustomServerService
	local self = setmetatable({
		IsInitialized = true :: true,
		_Server = nil :: CustomServer?,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, CustomServerService)

	-- the record is read before anything else of the game starts: on a private place it says what the server plays by
	if IS_RESERVED then
		local serverRes = load()
		if serverRes.IsOk then
			self._Server = serverRes.Value
		else
			warn(`this custom server runs unlisted: {serverRes.Value}`)
		end
	end
	local server = self._Server
	-- one that's joined without having been set up, or whose record is gone, plays by the rules of roleplay
	if BUILD_CONFIG.MODE == "private-server" then
		AttributeDefinition.set(Workspace, AttributeDefinition.IsPVP, server ~= nil and server.IsPVP)
	end
	if not IS_RESERVED then
		return self
	end

	-- whoever got in while the record was on its way
	if server then
		for _, player in Players:GetPlayers() do
			kickIfBanned(server, player)
		end
	end
	local heartbeatThread = task.spawn(run, self)
	table.insert(self._CleanUpCallbacks, function()
		local lastServer = self._Server
		if coroutine.status(heartbeatThread) == "suspended" then
			task.cancel(heartbeatThread)
		end
		-- a closing server isn't held up for this, a record that's left behind runs out by itself
		if lastServer then
			ServerRegistryUtil.removeCustomServer(lastServer.Id)
		end
	end)

	for _, command in COMMANDS do
		local inst = Instance.new("TextChatCommand")
		inst.Name = `{command.Name}Command`
		inst.PrimaryAlias = command.Alias
		inst.Parent = TextChatService
		table.insert(
			self._Connections,
			inst.Triggered:Connect(function(textSource: TextSource, message: string)
				execute(self, command, textSource.UserId, message)
			end)
		)
		table.insert(self._CleanUpCallbacks, function()
			inst:Destroy()
		end)
	end

	table.insert(
		self._Connections,
		Players.PlayerAdded:Connect(function(player: Player)
			if self._Server then
				kickIfBanned(self._Server, player)
			end
		end)
	)

	return self
end, function(self: CustomServerService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
