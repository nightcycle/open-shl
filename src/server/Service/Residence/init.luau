--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local ResidenceType = require("@game/ServerScriptService/Server/Type/Residence")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type ResidenceId = BaseType.ResidenceId
type Session = SessionService.Session
type ResidenceState = SessionType.ResidenceState
type Slot = ResidenceType.Slot
type Rooms = ResidenceType.Rooms
type Rule = ResidenceType.Rule
type ResidenceServiceImpl = {
	__index: ResidenceServiceImpl,
}
export type ResidenceService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Slots: { Slot }, -- in the order they're handed out
		_Owners: { [ResidenceId]: Player },
		_Hosts: { [Player]: Player }, -- whose residence a player is inside of, their own included
		_States: { [Player]: ResidenceState }, -- by owner: what the players inside were told last
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ResidenceServiceImpl
))
-- Constants
-- the residences of a game are its own, the ones of another game are never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		error(`shl1's flats are scenery`)
	end,
	shl2 = function(): Rule
		return require("@self/SHL2")
	end,
	shl3 = function(): Rule
		error(`shl3 has no apartments yet`)
	end,
})
assert(ResidenceType.Rule(RULE))
-- Variables
-- References
-- Private Functions
local function assign(self: ResidenceService, player: Player)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	for _, owner in self._Owners do
		if owner == player then
			return
		end
	end
	-- who gets a residence is the game's to say
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone or not RULE.GetIfHoused(sessionOpt.Value.Save) then
		return
	end
	for _, slot in self._Slots do
		if self._Owners[slot.Id] then
			continue
		end
		self._Owners[slot.Id] = player
		slot.SetOwner(player)
		AttributeDefinition.set(player, AttributeDefinition.ResidenceId, slot.Id)
		return
	end
	warn(`every residence is taken, {player.Name} goes without one`)
end

local function leave(self: ResidenceService, player: Player)
	local host = self._Hosts[player]
	if not host then
		return
	end
	self._Hosts[player] = nil
	for _, other in self._Hosts do
		if other == host then
			return
		end
	end
	-- nobody is left to tell of a change
	self._States[host] = nil
end

-- whoever is still inside is walked out by their own client as the owner goes
local function free(self: ResidenceService, player: Player)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	leave(self, player)
	for visitor, host in self._Hosts do
		if host == player then
			self._Hosts[visitor] = nil
		end
	end
	self._States[player] = nil
	for _, slot in self._Slots do
		if self._Owners[slot.Id] == player then
			self._Owners[slot.Id] = nil
			slot.SetOwner(nil)
		end
	end
	-- a client finds the owner of a door by it, the player is still around for a moment as the next one moves in
	AttributeDefinition.set(player, AttributeDefinition.ResidenceId, nil)
	-- somebody who came in while every residence was taken moves in now
	for _, other in Players:GetPlayers() do
		if other ~= player and SessionService:Get(other).IsSome then
			assign(self, other)
		end
	end
end

-- the lock only keeps the door shut, a visitor who's already inside stays
local function enter(self: ResidenceService, player: Player, residenceId: ResidenceId): Result<ResidenceState, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local owner = self._Owners[residenceId]
	local sessionOpt = if owner then SessionService:Get(owner) else nil
	if not owner or not sessionOpt or sessionOpt.IsNone then
		return Result.err(`nobody lives in "{residenceId}"`)
	end
	local save = sessionOpt.Value.Save
	if owner ~= player and RULE.GetIfLocked(save) then
		return Result.err(`the door is locked`)
	end
	leave(self, player)
	local state = RULE.NewState(residenceId, owner, save)
	self._Hosts[player] = owner
	self._States[owner] = state
	return Result.ok(state)
end
-- Class
local ResidenceService = {} :: ResidenceServiceImpl
ResidenceService.__index = ResidenceService

return ServiceLocker(function(): ResidenceService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local slots = RULE.GetSlots()
	for _, slot in slots do
		assert(ResidenceType.Slot(slot))
	end
	local self = setmetatable({
		IsInitialized = true :: true,
		_Slots = slots,
		_Owners = {},
		_Hosts = {},
		_States = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ResidenceService)

	NetworkService:Handle(
		RemoteDefinition.EnterResidence,
		function(player: Player, residenceId: ResidenceId): Result<ResidenceState, string>
			return enter(self, player, residenceId)
		end
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.LeaveResidence, function(player: Player)
			leave(self, player)
		end)
	)
	-- the game's own part asks about who's inside through this, it's never handed the service
	local rooms: Rooms = table.freeze({
		GetHost = function(player: Player): Player?
			return self._Hosts[player]
		end,
	})
	local stop = RULE.Start(rooms)
	if stop then
		table.insert(self._CleanUpCallbacks, stop)
	end

	-- whatever wrote to the save of an owner, the players inside only hear of it when what they see changed
	local changedConnection = SessionService.Changed:Connect(
		function(player: Player, session: Session, priorSession: Session)
			local priorState = self._States[player]
			if not priorState or session.Save == priorSession.Save then
				return
			end
			local state = RULE.NewState(priorState.ResidenceId, player, session.Save)
			if StateUtil.getIfEqual(state, priorState) then
				return
			end
			self._States[player] = state
			for visitor, host in self._Hosts do
				if host == player then
					NetworkService:Fire(RemoteDefinition.ResidenceChanged, visitor, state)
				end
			end
		end
	)
	local addedConnection = SessionService.Added:Connect(function(player: Player)
		assign(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		free(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		changedConnection:Disconnect()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
	end)
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			assign(self, player)
		end
	end

	table.insert(self._CleanUpCallbacks, function()
		for _, slot in self._Slots do
			local owner = self._Owners[slot.Id]
			if owner then
				AttributeDefinition.set(owner, AttributeDefinition.ResidenceId, nil)
			end
			slot.SetOwner(nil)
		end
	end)

	return self
end, function(self: ResidenceService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
