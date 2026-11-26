--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type PlayerSave = SaveType.PlayerSave
type PromoServiceImpl = {
	__index: PromoServiceImpl,
}
export type PromoService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PromoServiceImpl
))
-- Constants
-- nil in a game that has none
local GROUP_ID = ProductDefinition.GROUP_ID
-- Variables
-- References
-- Private Functions
-- yields. what the engine says right now, an err when it couldn't be asked: that's a web call
local function getIfMember(player: Player, groupId: number): Result<boolean, string>
	local success, value = pcall(function(): boolean
		return player:IsInGroupAsync(groupId)
	end)
	return if success then Result.ok(value == true) else Result.err(tostring(value))
end

-- yields. answers whether a player has what the members of the group are handed. whoever has it isn't asked about:
-- it's written down the first time they're seen in the group + never taken back, in the group or out of it
local function check(self: PromoService, player: Player, groupId: number): Result<boolean, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if SessionService:GetOwned(player).HasGroupPerk == true then
		return Result.ok(true)
	end
	local memberRes = getIfMember(player, groupId)
	-- they can be gone by the time an answer is in, so can the service
	if not self.IsInitialized or not SessionService.IsInitialized or SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if memberRes.IsErr then
		warn(`promo err: the group of {player.Name}: {memberRes.Value}`)
		return Result.err(`the group couldn't be asked about`)
	end
	if not memberRes.Value then
		return Result.ok(false)
	end
	local saveRes = SessionService:Update(player, function(save: PlayerSave): PlayerSave?
		local section = save.SHL1
		assert(section, `a save of this game has its section`)
		section.IsGroupPerkGranted = true
		return save
	end)
	if saveRes.IsErr then
		return Result.err(saveRes.Value)
	end
	return Result.ok(true)
end
-- Class
local PromoService = {} :: PromoServiceImpl
PromoService.__index = PromoService

-- what being in the group of the game gives: whoever is seen in it once has what its members are handed for good.
-- it's looked at as a session starts, off the way in, + again whenever the player asks, so somebody who joined the
-- group meanwhile doesn't have to come back for it. what it opens is the game's to say, by the lock of the group
return ServiceLocker(function(): PromoService
	assert(GROUP_ID ~= nil, `the game is listed for a promo it has no group for`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local groupId: number = GROUP_ID
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, PromoService)

	NetworkService:Handle(RemoteDefinition.CheckGroupPerk, function(player: Player): Result<boolean, string>
		return check(self, player, groupId)
	end)

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		task.spawn(check, self, player, groupId)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
	end)
	-- whoever had a session before this was up
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			task.spawn(check, self, player, groupId)
		end
	end

	return self
end, function(self: PromoService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
