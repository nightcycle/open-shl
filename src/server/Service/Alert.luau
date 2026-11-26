--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local TeamService = require("@game/ServerScriptService/Server/Service/Team")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
type AlertServiceImpl = {
	__index: AlertServiceImpl,
	Announce: (self: AlertService, text: string, players: { Player }?) -> (),
}
export type AlertService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AlertServiceImpl
))
-- Constants
-- the side the town calls on when something is up
local AUDIENCE_TEAM_ID: TeamId = "Heroes"
-- Variables
-- References
-- Private Functions
-- whoever is on the side that's called on right now. a place without sides has nobody on one
local function getAudience(): { Player }
	assert(TeamService.IsInitialized, `the team service isn't initialized`)
	local players: { Player } = {}
	for _, player in Players:GetPlayers() do
		if TeamService:GetTeamId(player) == AUDIENCE_TEAM_ID then
			table.insert(players, player)
		end
	end
	return players
end
-- Class
local AlertService = {} :: AlertServiceImpl
AlertService.__index = AlertService

-- with a list it's read by exactly those, whatever side they're on. without one by everybody the town calls on
function AlertService:Announce(text: string, players: { Player }?)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local audience: { Player } = if players then players else getAudience()
	for _, player in audience do
		-- somebody who was listed + left since
		if player:IsDescendantOf(Players) then
			NetworkService:Fire(RemoteDefinition.Alert, player, text)
		end
	end
end

-- the line the town puts on the screens of its heroes: a bank that's robbed, a disaster that's under way. the old
-- place sent every line to everybody + had each client decide if it was theirs to read, here the server picks who
-- is sent one
return ServiceLocker(function(): AlertService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(TeamService.IsInitialized, `the team service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AlertService)

	return self
end, function(self: AlertService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
