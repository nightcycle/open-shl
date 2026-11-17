--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local ProfileType = require("@game/ReplicatedStorage/Shared/Type/Profile")
type Result<V, E> = TypeUnionLib.Result<V, E>
type PublicProfile = ProfileType.PublicProfile
type ProfileServiceImpl = {
	__index: ProfileServiceImpl,
	List: (self: ProfileService) -> { PublicProfile },
}
export type ProfileService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- what the database menu of every client shows for a player, trimmed out of their active character
		_Profiles: { [Player]: PublicProfile? },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ProfileServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- the only place that decides what one player may know about another
local function newProfile(player: Player): PublicProfile?
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local characterOpt = SessionService:GetActiveCharacter(player)
	if characterOpt.IsNone then
		return nil
	end
	local main = characterOpt.Value.Identities.Main
	local secret = characterOpt.Value.Identities.Secret
	local out: PublicProfile = {
		UserId = player.UserId,
		UserName = player.Name,
		AliasName = main.Profile.Name,
		IdentityName = if secret then secret.Profile.Name else "",
		-- one alignment + backstory per character, kept on the super identity
		Alignment = main.Profile.Alignment,
		Backstory = main.Profile.Backstory,
	}
	table.freeze(out)
	return out
end

local function getIfSame(profile: PublicProfile, other: PublicProfile): boolean
	return profile.UserId == other.UserId
		and profile.UserName == other.UserName
		and profile.AliasName == other.AliasName
		and profile.IdentityName == other.IdentityName
		and profile.Alignment == other.Alignment
		and profile.Backstory == other.Backstory
end

-- every client holds the whole roster, so it's sent again whenever a line of it changed
local function set(self: ProfileService, player: Player, profile: PublicProfile?)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local priorProfile = self._Profiles[player]
	if profile == priorProfile or (profile and priorProfile and getIfSame(profile, priorProfile)) then
		return
	end
	self._Profiles[player] = profile
	NetworkService:FireAll(RemoteDefinition.ProfilesChanged, self:List())
end
-- Class
local ProfileService = {} :: ProfileServiceImpl
ProfileService.__index = ProfileService

-- one profile per player with a session, in the order the server lists its players
function ProfileService:List(): { PublicProfile }
	local out: { PublicProfile } = {}
	for _, player in Players:GetPlayers() do
		local profile = self._Profiles[player]
		if profile then
			table.insert(out, profile)
		end
	end
	table.freeze(out)
	return out
end

return ServiceLocker(function(): ProfileService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Profiles = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ProfileService)

	NetworkService:Handle(RemoteDefinition.GetProfiles, function(): Result<{ PublicProfile }, string>
		return Result.ok(self:List())
	end)

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		set(self, player, newProfile(player))
	end)
	-- another slot or an edit of the worn one, a swap of the identity leaves the profile as it is
	local activeCharacterConnection = SessionService.ActiveCharacterChanged:Connect(function(player: Player)
		set(self, player, newProfile(player))
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		set(self, player, nil)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		activeCharacterConnection:Disconnect()
		removingConnection:Disconnect()
	end)
	for _, player in Players:GetPlayers() do
		set(self, player, newProfile(player))
	end

	return self
end, function(self: ProfileService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
