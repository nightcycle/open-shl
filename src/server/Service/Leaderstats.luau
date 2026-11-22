--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
type Session = SessionService.Session
type LeaderstatsServiceImpl = {
	__index: LeaderstatsServiceImpl,
}
export type LeaderstatsService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the column of every player with a session
		_Credits: { [Player]: IntValue },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: LeaderstatsServiceImpl
))
-- Constants
-- the engine lists a player with whatever sits under them in a folder of this name, a column to a value
local FOLDER_NAME = "leaderstats"
-- the one column of the old place
local CREDITS_NAME = "Credits"
local CREDITS_CURRENCY: PseudoEnum.Currency = PseudoEnum.Currency.Credits
-- Variables
-- References
-- Private Functions
local function add(self: LeaderstatsService, player: Player, session: Session)
	if self._Credits[player] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	local credits = Instance.new("IntValue")
	credits.Name = CREDITS_NAME
	credits.Value = session.Save.Balances[CREDITS_CURRENCY]
	credits.Parent = folder
	-- the list reads a folder as it comes in, so the column is under it by then
	folder.Parent = player
	self._Credits[player] = credits
end

local function remove(self: LeaderstatsService, player: Player)
	local credits = self._Credits[player]
	self._Credits[player] = nil
	local folder = if credits then credits.Parent else nil
	if folder then
		folder:Destroy()
	end
end
-- Class
local LeaderstatsService = {} :: LeaderstatsServiceImpl
LeaderstatsService.__index = LeaderstatsService

-- what a player has to spend, in the list of players the engine draws: the old place showed it nowhere else. the
-- column is the server's from the session, a client that writes to its copy changes what it sees + nothing else
return ServiceLocker(function(): LeaderstatsService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Credits = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, LeaderstatsService)

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		local sessionOpt = SessionService:Get(player)
		if sessionOpt.IsSome then
			add(self, player, sessionOpt.Value)
		end
	end)
	local changedConnection = SessionService.Changed:Connect(function(player: Player, session: Session)
		local credits = self._Credits[player]
		if credits then
			credits.Value = session.Save.Balances[CREDITS_CURRENCY]
		end
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		changedConnection:Disconnect()
		removingConnection:Disconnect()
		for player in self._Credits do
			remove(self, player)
		end
	end)
	for _, player in Players:GetPlayers() do
		local sessionOpt = SessionService:Get(player)
		if sessionOpt.IsSome then
			add(self, player, sessionOpt.Value)
		end
	end

	return self
end, function(self: LeaderstatsService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
