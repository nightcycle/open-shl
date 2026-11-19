--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PlayerModeUtil = require("@game/ServerScriptService/Server/Util/PlayerMode")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type PlayerSave = SaveType.PlayerSave
-- where the save of a game keeps whether its player sat fights out
type Field = {
	Get: (save: PlayerSave) -> boolean,
	Set: (save: PlayerSave, isPeaceful: boolean) -> (),
}
type PlayerModeServiceImpl = {
	__index: PlayerModeServiceImpl,
	GetIfPeaceful: (self: PlayerModeService, player: Player) -> boolean,
	SetPeaceful: (self: PlayerModeService, player: Player, isPeaceful: boolean) -> Result<true, string>,
}
export type PlayerModeService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PlayerModeServiceImpl
))
-- Constants
-- the pick is the player's + outlasts a visit, so it's with what its game keeps of them: a game that has its players
-- pick says where
local FIELD: Field = GameDefinition.pick({
	shl1 = function(): Field
		return {
			Get = function(save: PlayerSave): boolean
				local section = save.SHL1
				assert(section, `a save of this game has its section`)
				return section.IsPeaceful
			end,
			Set = function(save: PlayerSave, isPeaceful: boolean)
				local section = save.SHL1
				assert(section, `a save of this game has its section`)
				section.IsPeaceful = isPeaceful
			end,
		}
	end,
	shl2 = function(): Field
		error(`shl2 has nobody pick whether they fight`)
	end,
	shl3 = function(): Field
		error(`shl3 has nobody pick whether they fight`)
	end,
})
-- Variables
-- References
-- Private Functions
-- Class
local PlayerModeService = {} :: PlayerModeServiceImpl
PlayerModeService.__index = PlayerModeService

-- whoever has no session yet fights, the way everybody starts out
function PlayerModeService:GetIfPeaceful(player: Player): boolean
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	return sessionOpt.IsSome and FIELD.Get(sessionOpt.Value.Save)
end

-- the pick is kept first, then the avatar that's out is dealt with. a pick that changes nothing does nothing
function PlayerModeService:SetPeaceful(player: Player, isPeaceful: boolean): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if FIELD.Get(sessionOpt.Value.Save) == isPeaceful then
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	local saveRes = SessionService:Update(player, function(save: PlayerSave): PlayerSave?
		FIELD.Set(save, isPeaceful)
		return save
	end)
	if saveRes.IsErr then
		return saveRes
	end
	PlayerModeUtil.change(player.Character, AvatarService:GetIfHeld(player), isPeaceful)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

return ServiceLocker(function(): PlayerModeService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	-- the pick would be kept + written onto every avatar without anything ever reading it
	assert(CombatDefinition.IS_OPTIONAL, `the rule of {GameDefinition.ID} has nobody sit a fight out`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, PlayerModeService)

	-- nothing about the pick is taken from the client but that it was made: what it came to is on the avatar
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetPeaceful, function(player: Player, isPeaceful: boolean)
			local setRes = self:SetPeaceful(player, isPeaceful)
			if setRes.IsErr then
				warn(`mode err: {setRes.Value}`)
			end
		end)
	)

	local spawnedConnection = AvatarService.Spawned:Connect(function(player: Player, character: Model)
		PlayerModeUtil.apply(character, self:GetIfPeaceful(player))
	end)
	table.insert(self._CleanUpCallbacks, function()
		spawnedConnection:Disconnect()
	end)
	-- the avatars that came in before this was up
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and SessionService:Get(player).IsSome then
			PlayerModeUtil.apply(character, self:GetIfPeaceful(player))
		end
	end

	return self
end, function(self: PlayerModeService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
