--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
type Session = SessionService.Session
-- what the list says of every player under one heading
type Column = {
	Name: string,
	ClassName: "IntValue" | "StringValue",
	Get: (session: Session) -> number | string,
}
type LeaderstatsServiceImpl = {
	__index: LeaderstatsServiceImpl,
}
export type LeaderstatsService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the columns of every player with a session, in the order of the game's
		_Values: { [Player]: { ValueBase } },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: LeaderstatsServiceImpl
))
-- Constants
local isColumn = Type.strictInterface({
	Name = Type.string,
	ClassName = Type.literal("IntValue", "StringValue"),
	Get = Type.callback,
})
-- the engine lists a player with whatever sits under them in a folder of this name, a column to a value
local FOLDER_NAME = "leaderstats"
-- what a game tells of its players there is its own, in the order the engine draws it in. the columns of another
-- game are never required
local COLUMNS: { Column } = GameDefinition.pick({
	shl1 = function(): { Column }
		return require("@self/SHL1")
	end,
	shl2 = function(): { Column }
		error(`shl2 tells nothing of its players in the list`)
	end,
	shl3 = function(): { Column }
		return require("@self/SHL3")
	end,
})
do
	local names: { [string]: true } = {}
	for _, column in COLUMNS do
		assert(isColumn(column))
		assert(not names[column.Name], `the "{column.Name}" column is listed twice`)
		names[column.Name] = true
	end
end
-- Variables
-- References
-- Private Functions
local function write(values: { ValueBase }, session: Session)
	for index, column in COLUMNS do
		local value, content = values[index], column.Get(session)
		local isFitting = if value:IsA("IntValue") then typeof(content) == "number" else typeof(content) == "string"
		if isFitting then
			-- the checker knows a value by what the two classes share, which isn't what they hold
			(value :: any).Value = content
		else
			warn(`leaderstats err: the "{column.Name}" column is no {typeof(content)}`)
		end
	end
end

local function add(self: LeaderstatsService, player: Player, session: Session)
	if self._Values[player] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	local values: { ValueBase } = {}
	for index, column in COLUMNS do
		local value: ValueBase = if column.ClassName == "IntValue"
			then Instance.new("IntValue")
			else Instance.new("StringValue")
		value.Name = column.Name
		values[index] = value
	end
	write(values, session)
	for _, value in values do
		value.Parent = folder
	end
	-- the list reads a folder as it comes in, so the columns are under it by then
	folder.Parent = player
	self._Values[player] = values
end

local function remove(self: LeaderstatsService, player: Player)
	local values = self._Values[player]
	self._Values[player] = nil
	local folder = if values and values[1] then values[1].Parent else nil
	if folder then
		folder:Destroy()
	end
end
-- Class
local LeaderstatsService = {} :: LeaderstatsServiceImpl
LeaderstatsService.__index = LeaderstatsService

-- what the game tells of a player in the list of players the engine draws: the old places showed it nowhere else. the
-- columns are the server's from the session, a client that writes to its copy changes what it sees + nothing else
return ServiceLocker(function(): LeaderstatsService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Values = {},
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
		local values = self._Values[player]
		if values then
			write(values, session)
		end
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		changedConnection:Disconnect()
		removingConnection:Disconnect()
		for player in self._Values do
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
