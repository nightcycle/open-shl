--!strict
-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local BalanceUtil = require("@self/Balance")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
local TeamDefinition = require("@game/ServerScriptService/Server/Definition/Team")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type Result<V, E> = TypeUnionLib.Result<V, E>
type TeamId = CombatType.TeamId
type TeamServiceImpl = {
	__index: TeamServiceImpl,
	GetTeamId: (self: TeamService, player: Player) -> TeamId?,
	ChangeTeam: (self: TeamService, player: Player) -> Result<TeamId, string>,
}
export type TeamService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- an avatar came in on a side: it says which, + that it downed nobody yet
		Deployed: Signal.Signal<Player, Model, TeamId>,
		-- none in a place where nobody fights: nobody takes a side there
		_Teams: { [TeamId]: Team },
		-- none of it is saved: whoever comes back is put where there's room
		_TeamIds: { [Player]: TeamId },
		_AvatarConnections: { [Player]: RBXScriptConnection },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: TeamServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function count(self: TeamService): BalanceUtil.Counts
	local counts: BalanceUtil.Counts = {}
	for _, side in TeamDefinition.SIDES do
		counts[side.Id] = 0
	end
	for _, teamId: TeamId in self._TeamIds do
		counts[teamId] += 1
	end
	return counts
end

-- the engine lists who's on which side as well, nothing here reads it back
local function assign(self: TeamService, player: Player, teamId: TeamId)
	self._TeamIds[player] = teamId
	player.Team = self._Teams[teamId]
end

-- whoever took the last of the health of a body is paid what was on its head, + has more on their own for it
local function onDowned(victim: Model)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local userId = AttributeDefinition.get(victim, AttributeDefinition.DownedBy)
	local attacker = if userId then Players:GetPlayerByUserId(userId) else nil
	if not attacker or SessionService:Get(attacker).IsNone then
		return
	end
	local bounty = CombatDefinition.getBounty(victim)
	if bounty then
		local grantRes = EconomyService:Grant(attacker, PseudoEnum.Currency.Credits, bounty)
		if grantRes.IsErr then
			warn(`bounty err: {grantRes.Value}`)
		end
	end
	-- only a body that's up counts what it downs: the one somebody comes back as starts over
	local avatar = attacker.Character
	local killStreak = if avatar then AttributeDefinition.get(avatar, AttributeDefinition.KillStreak) else nil
	if avatar and killStreak and TakeDownUtil.getIfAlive(avatar) then
		AttributeDefinition.set(avatar, AttributeDefinition.KillStreak, killStreak + 1)
	end
end

-- an avatar is on the side its player has as it comes in + stays on it for as long as it's in the world
local function deploy(self: TeamService, player: Player, character: Model)
	local teamId: TeamId? = self:GetTeamId(player)
	if not teamId then
		return
	end
	AttributeDefinition.set(character, AttributeDefinition.TeamId, teamId)
	AttributeDefinition.set(character, AttributeDefinition.KillStreak, 0)
	local priorConnection = self._AvatarConnections[player]
	if priorConnection then
		priorConnection:Disconnect()
	end
	-- the hit that took the last of its health is the only one that says who did: a body that's down takes no other,
	-- so it's said once
	local connection: RBXScriptConnection
	connection = character:GetAttributeChangedSignal(AttributeDefinition.DownedBy.Name):Connect(function()
		if AttributeDefinition.get(character, AttributeDefinition.DownedBy) == nil then
			return
		end
		connection:Disconnect()
		if self.IsInitialized then
			onDowned(character)
		end
	end)
	self._AvatarConnections[player] = connection
	self.Deployed:Fire(player, character, teamId)
end

local function remove(self: TeamService, player: Player)
	local connection = self._AvatarConnections[player]
	if connection then
		connection:Disconnect()
	end
	self._AvatarConnections[player] = nil
	self._TeamIds[player] = nil
end
-- Class
local TeamService = {} :: TeamServiceImpl
TeamService.__index = TeamService

-- nil in a place without sides + for a player without a session. whoever is asked about for the first time is put on
-- the side with fewer players
function TeamService:GetTeamId(player: Player): TeamId?
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if next(self._Teams) == nil then
		return nil
	end
	local teamId: TeamId? = self._TeamIds[player]
	if teamId then
		return teamId
	end
	if SessionService:Get(player).IsNone then
		return nil
	end
	local joinTeamId: TeamId = BalanceUtil.getJoinTeamId(count(self), TeamDefinition.JOIN_TEAM_ID)
	assign(self, player, joinTeamId)
	return joinTeamId
end

-- the player goes over to the other side, unless that leaves the sides too far apart. nobody changes sides on a body
-- that's been in the world: the avatar that's out is taken down as it is, on the side it came in on, + the one that
-- comes back is the first on the new one. it's a way out of a fight + out of a cell, as it was in the old place
function TeamService:ChangeTeam(player: Player): Result<TeamId, string>
	local teamId: TeamId? = self:GetTeamId(player)
	if not teamId then
		return Result.err(`{player.Name} has no side to leave`)
	end
	if not BalanceUtil.getIfSwitchAllowed(count(self), teamId, TeamDefinition.MAX_LEAD) then
		return Result.err(TeamDefinition.REFUSAL_TEXT)
	end
	local otherTeamId: TeamId = BalanceUtil.getOther(teamId)
	assign(self, player, otherTeamId)
	local character = player.Character
	if character and TakeDownUtil.getIfAlive(character) then
		TakeDownUtil.takeDown(character)
	end
	return Result.ok(otherTeamId :: any) :: TypeUnionLib.Ok<TeamId>
end

-- the sides of a place where players fight: who's on which, written onto every avatar as it comes in for the rule
-- of its fights to read, + what downing somebody pays. the one thing a client says is that it wants the other side
return ServiceLocker(function(): TeamService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	-- the sides would be made + written onto every avatar without anything ever reading them
	assert(
		CombatDefinition.IS_TEAM_SAFE or CombatDefinition.BOUNTY ~= nil,
		`the rule of {GameDefinition.ID} has no use for sides`
	)
	local self = setmetatable({
		IsInitialized = true :: true,
		Deployed = Signal.new() :: Signal.Signal<Player, Model, TeamId>,
		_Teams = {} :: { [TeamId]: Team },
		_TeamIds = {} :: { [Player]: TeamId },
		_AvatarConnections = {} :: { [Player]: RBXScriptConnection },
		_CleanUpCallbacks = {},
		_Connections = {},
	}, TeamService)

	-- nothing about the side is taken from the client but that another one is wanted. where there are none the answer
	-- is an error
	NetworkService:Handle(RemoteDefinition.ChangeTeam, function(player: Player): Result<TeamId, string>
		return self:ChangeTeam(player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		self.Deployed:Destroy()
	end)
	-- a place where nobody fights has nobody take a side
	if not ModeDefinition.getIfPVPEnabled() then
		return self
	end

	-- nobody is put anywhere by the engine: it knows who's in, not who has a session
	for _, side in TeamDefinition.SIDES do
		local team = Instance.new("Team")
		team.Name = side.Name
		team.TeamColor = BrickColor.new(side.BrickColorNumber)
		team.AutoAssignable = false
		team.Parent = Teams
		self._Teams[side.Id] = team
	end

	local spawnedConnection = AvatarService.Spawned:Connect(function(player: Player, character: Model)
		deploy(self, player, character)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		spawnedConnection:Disconnect()
		removingConnection:Disconnect()
		for _, connection in self._AvatarConnections do
			connection:Disconnect()
		end
		for _, team in self._Teams do
			team:Destroy()
		end
	end)
	-- the avatars that came in before this was up
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and SessionService:Get(player).IsSome then
			deploy(self, player, character)
		end
	end

	return self
end, function(self: TeamService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
