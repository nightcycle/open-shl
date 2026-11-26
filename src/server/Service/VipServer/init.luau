--!strict
-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local OwnerUtil = require("@self/Owner")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type VipServerServiceImpl = {
	__index: VipServerServiceImpl,
	SetPVP: (self: VipServerService, isPVP: boolean) -> (),
}
export type VipServerService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: VipServerServiceImpl
))
-- Constants
-- neither changes for as long as a server lives
local PRIVATE_SERVER_ID = game.PrivateServerId
local OWNER_ID = game.PrivateServerOwnerId
-- every text below ends up in front of a player as it is
local REFUSAL_TEXT = `only the owner of a private server can do that`
-- new words: the old place told nobody its server had changed what it plays by
local PVP_TEXT = `This server is now in PVP mode`
local ROLEPLAY_TEXT = `This server is now in RP mode`
-- Variables
-- References
-- Private Functions
-- a line for everybody who's in, whatever side they were on: the sides are gone or only just made as it's sent. a
-- game without sides has no strip to put it on
local function announce(text: string)
	if not GameDefinition.FEATURES.Teams then
		return
	end
	local AlertService = require("@game/ServerScriptService/Server/Service/Alert")
	if AlertService.IsInitialized then
		AlertService:Announce(text, Players:GetPlayers())
	end
end

-- a client is told if the server is theirs. nothing it says about that is ever read
local function mark(player: Player)
	local isOwner = OwnerUtil.getIfOwner(PRIVATE_SERVER_ID, OWNER_ID, player.UserId)
	AttributeDefinition.set(player, AttributeDefinition.IsServerOwner, isOwner)
end
-- Class
local VipServerService = {} :: VipServerServiceImpl
VipServerService.__index = VipServerService

-- everything that goes by whether players fight hears of it through the mode: the sides, the jail, what the town's
-- villains get up to. the same answer twice changes nothing + is told to nobody
function VipServerService:SetPVP(isPVP: boolean)
	if AttributeDefinition.get(Workspace, AttributeDefinition.IsPVP) == isPVP then
		return
	end
	AttributeDefinition.set(Workspace, AttributeDefinition.IsPVP, isPVP)
	announce(if isPVP then PVP_TEXT else ROLEPLAY_TEXT)
end

-- what a server of the game plays by: what its place was built for, until the owner of a private one says otherwise.
-- the old place took that word from any client of any server, here it's the owner's alone + only on a server the
-- engine says is theirs. nothing of it is saved: a server that empties + starts again plays by its place
return ServiceLocker(function(): VipServerService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	-- there its owner set it up before it started, + another service says so
	assert(BUILD_CONFIG.MODE ~= "private-server", `a custom server is no server to toggle`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, VipServerService)

	-- written on every server of the game, so there's one place to ask whether players fight
	AttributeDefinition.set(Workspace, AttributeDefinition.IsPVP, BUILD_CONFIG.PVP_ENABLED)
	AttributeDefinition.set(
		Workspace,
		AttributeDefinition.IsPrivateServer,
		OwnerUtil.getIfOwned(PRIVATE_SERVER_ID, OWNER_ID)
	)

	table.insert(self._Connections, Players.PlayerAdded:Connect(mark))
	for _, player in Players:GetPlayers() do
		mark(player)
	end

	-- bound on a public server as well: a function nobody handles keeps its caller waiting for good
	NetworkService:Handle(
		RemoteDefinition.SetServerPVP,
		function(player: Player, isPVP: boolean): Result<boolean, string>
			if not OwnerUtil.getIfOwner(PRIVATE_SERVER_ID, OWNER_ID, player.UserId) then
				return Result.err(REFUSAL_TEXT)
			end
			self:SetPVP(isPVP)
			return Result.ok(isPVP)
		end
	)

	return self
end, function(self: VipServerService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
