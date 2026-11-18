--!strict
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Driver = require("@game/ReplicatedStorage/Shared/VFX/Driver")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Scope = require("@game/ReplicatedStorage/Shared/VFX/Scope")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type VFX = VFXType.VFX
type Subject = VFXType.Subject
type Audience = VFXType.Audience
type Reach = VFXType.Reach
type Replication = VFXType.Replication
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type Message = VFXType.Message
type ServerScope = VFXType.ServerScope
-- a state effect clients are holding right now, whoever joins late is caught up on it
type ShownState = {
	Message: Message,
	Subject: Subject,
	Replication: Replication,
}
type VFXServiceImpl = {
	__index: VFXServiceImpl,
	NewScope: (self: VFXService, player: Player?, character: Model?) -> ServerScope,
	SetRelays: (self: VFXService, player: Player, relays: { [string]: Reach }?) -> (),
}
export type VFXService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Driver: VFXType.Driver,
		_ShownStates: { [string]: ShownState },
		-- what stops the states a player's own machine has everybody else hold, by the id it gave them
		_ReportedStates: { [Player]: { [string]: Cleanup } },
		-- the effects the machine of a player may pass on to everybody else, by name, + how far they go
		_Relays: { [Player]: { [string]: Reach } },
		_PlayerConnections: { [Player]: { RBXScriptConnection } },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: VFXServiceImpl
))
-- Constants
-- more than a character can honestly be holding at once
local MAX_REPORTED_STATE_COUNT = 16
-- Variables
-- References
-- Private Functions
local function getIfInAudience(player: Player, subject: Subject, audience: Audience?): boolean
	if audience == "Owner" then
		return player == subject.Player
	elseif audience == "Others" then
		return player ~= subject.Player
	end
	return true
end

-- the replication: who of the audience an effect is worth telling. an event far from somebody is over before they
-- could get there, a state may still be on when they do
local function getRecipients(vfx: VFX, subject: Subject, replication: Replication): { Player }
	local recipients: { Player } = {}
	local range = replication.Range
	local origin = if vfx.Kind == "Event"
			and range
			and subject.Character
		then subject.Character:GetPivot().Position
		else nil
	for _, player in Players:GetPlayers() do
		if not getIfInAudience(player, subject, replication.Audience) then
			continue
		end
		if origin and range and player ~= subject.Player then
			local character = player.Character
			if not character or (character:GetPivot().Position - origin).Magnitude > range then
				continue
			end
		end
		table.insert(recipients, player)
	end
	return recipients
end

local function send(recipients: { Player }, message: Message)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	for _, player in recipients do
		NetworkService:Fire(RemoteDefinition.VFXReplicated, player, message)
	end
end

local function fireClient(vfx: VFX, props: unknown, subject: Subject, replication: Replication)
	send(
		getRecipients(vfx, subject, replication),
		table.freeze({
			Type = "Fire" :: "Fire",
			Name = vfx.Name,
			Props = props,
			Character = subject.Character,
			-- a client culls by where its camera is, which only it knows
			Range = replication.Range,
			MinQualityLevel = replication.MinQualityLevel,
		})
	)
end

local function startClient(
	self: VFXService,
	vfx: VFX,
	props: unknown,
	subject: Subject,
	swap: Swap?,
	replication: Replication
): Cleanup
	local id = HttpService:GenerateGUID(false)
	local message: Message = table.freeze({
		Type = "Start" :: "Start",
		Name = vfx.Name,
		Props = props,
		Character = subject.Character,
		Id = id,
		Swap = swap,
		MinQualityLevel = replication.MinQualityLevel,
	})
	self._ShownStates[id] = table.freeze({
		Message = message,
		Subject = subject,
		Replication = replication,
	})
	send(getRecipients(vfx, subject, replication), message)
	return function(stopSwap: Swap?)
		if not self.IsInitialized or not self._ShownStates[id] then
			return
		end
		self._ShownStates[id] = nil
		send(
			getRecipients(vfx, subject, replication),
			table.freeze({
				Type = "Stop" :: "Stop",
				Id = id,
				Swap = stopSwap,
			})
		)
	end
end

local function stopReportedStates(self: VFXService, player: Player)
	local cleanups = self._ReportedStates[player]
	self._ReportedStates[player] = nil
	if cleanups then
		for _, cleanup in cleanups do
			cleanup(nil)
		end
	end
end

-- a client may only ever pass on what its own machine does to its own avatar: one of its abilities has to let the
-- effect through, the props have to be what the effect takes + neither whose avatar it's on nor how far it goes is
-- the client's to say
local function onReported(self: VFXService, player: Player, message: Message)
	local character = player.Character
	if not character then
		return
	end
	local cleanups: { [string]: Cleanup } = self._ReportedStates[player] or {}
	self._ReportedStates[player] = cleanups
	if message.Type == "Stop" then
		local cleanup = cleanups[message.Id]
		cleanups[message.Id] = nil
		if cleanup then
			cleanup(message.Swap)
		end
		return
	end
	local vfxRes = ClientVFXDefinition.get(message.Name)
	local reach = (self._Relays[player] or {})[message.Name]
	if vfxRes.IsErr or not reach then
		warn(`dropped the "{message.Name}" effect of {player.Name}: it isn't theirs to show`)
		return
	end
	local replication: Replication = table.freeze({
		Audience = "Others" :: "Others",
		Range = reach.Range,
		MinQualityLevel = reach.MinQualityLevel,
	})
	local vfx = vfxRes.Value
	local success, msg = vfx.Props(message.Props)
	if not success then
		warn(`dropped the "{message.Name}" effect of {player.Name}: {msg}`)
		return
	end
	local subject: Subject = table.freeze({
		Character = character,
		Player = player,
		IsOwner = false,
	})
	if message.Type == "Fire" and vfx.Kind == "Event" then
		fireClient(vfx, message.Props, subject, replication)
	elseif message.Type == "Start" and vfx.Kind == "State" then
		local count = 0
		for _ in cleanups do
			count += 1
		end
		if cleanups[message.Id] or count >= MAX_REPORTED_STATE_COUNT then
			return
		end
		cleanups[message.Id] = startClient(self, vfx, message.Props, subject, message.Swap, replication)
	end
end

local function onPlayerAdded(self: VFXService, player: Player)
	for _, shownState in self._ShownStates do
		if getIfInAudience(player, shownState.Subject, shownState.Replication.Audience) then
			send({ player }, shownState.Message)
		end
	end
	self._PlayerConnections[player] = {
		-- what a player has others hold is on their avatar, it goes with it
		player.CharacterRemoving:Connect(function()
			stopReportedStates(self, player)
		end),
	}
end

local function onPlayerRemoving(self: VFXService, player: Player)
	local connections: { RBXScriptConnection } = self._PlayerConnections[player] or {}
	for _, v in connections do
		v:Disconnect()
	end
	self._PlayerConnections[player] = nil
	self._Relays[player] = nil
	stopReportedStates(self, player)
end
-- Class
local VFXService = {} :: VFXServiceImpl
VFXService.__index = VFXService

-- what the effects of a character are run with on the server. without a character they're the world's own
function VFXService:NewScope(player: Player?, character: Model?): ServerScope
	assert(self.IsInitialized, `the vfx service isn't initialized`)
	local scope = Scope.new(
		table.freeze({
			Character = character,
			Player = player,
			IsOwner = false,
		}),
		self._Driver
	)
	return scope
end

-- which client effects the machine of the player may pass on, as their abilities have it. nil: none
function VFXService:SetRelays(player: Player, relays: { [string]: Reach }?)
	assert(self.IsInitialized, `the vfx service isn't initialized`)
	self._Relays[player] = relays :: any
end

return ServiceLocker(function(): VFXService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local self: VFXService
	self = setmetatable({
		IsInitialized = true :: true,
		_Driver = Driver.new({
			RunsServer = true,
			FireClient = fireClient,
			StartClient = function(
				vfx: VFX,
				props: unknown,
				subject: Subject,
				swap: Swap?,
				replication: Replication
			): Cleanup?
				return startClient(self, vfx, props, subject, swap, replication)
			end,
		}),
		_ShownStates = {},
		_ReportedStates = {},
		_Relays = {},
		_PlayerConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, VFXService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.VFXReported, function(player: Player, message: Message)
			onReported(self, player, message)
		end)
	)
	table.insert(
		self._Connections,
		Players.PlayerAdded:Connect(function(player: Player)
			onPlayerAdded(self, player)
		end)
	)
	table.insert(
		self._Connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			onPlayerRemoving(self, player)
		end)
	)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(self, player)
	end

	return self
end, function(self: VFXService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, connections in self._PlayerConnections do
		for _, v in connections do
			v:Disconnect()
		end
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
