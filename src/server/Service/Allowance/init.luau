--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TimerUtil = require("@self/Timer")
-- Types
type AllowanceServiceImpl = {
	__index: AllowanceServiceImpl,
}
export type AllowanceService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the beat of everybody who has a session, nothing of it is kept between two visits
		_Threads: { [Player]: thread },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AllowanceServiceImpl
))
-- Constants
-- nil in a game that has none
local ALLOWANCE = ProductDefinition.ALLOWANCE
-- Variables
-- References
-- Private Functions
local function remove(self: AllowanceService, player: Player)
	local thread = self._Threads[player]
	if thread then
		TimerUtil.stop(thread)
	end
	self._Threads[player] = nil
end

-- the beat starts once the session is there, which is when the old places had read the save
local function add(self: AllowanceService, player: Player)
	local allowance = ALLOWANCE
	if allowance == nil or self._Threads[player] then
		return
	end
	local isWarned = false
	self._Threads[player] = TimerUtil.start(allowance.INTERVAL, function()
		if not EconomyService.IsInitialized then
			return
		end
		local grantRes = EconomyService:Grant(player, allowance.CURRENCY, allowance.AMOUNT)
		if grantRes.IsErr and not isWarned then
			isWarned = true
			warn(`allowance err: {grantRes.Value}`)
		end
	end)
end
-- Class
local AllowanceService = {} :: AllowanceServiceImpl
AllowanceService.__index = AllowanceService

-- what everybody is handed for being in a server, each on a beat of their own that starts with their session + ends
-- with it. it asks about nothing: not a menu, a side, the jail or whether anybody is at the keys. the balance is all
-- that's saved of it, by the beat every save is written on
return ServiceLocker(function(): AllowanceService
	assert(ALLOWANCE ~= nil, `the game is listed for an allowance it has no row for`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Threads = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AllowanceService)

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		add(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
		for player in table.clone(self._Threads) do
			remove(self, player)
		end
	end)
	-- whoever had a session before this was up
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			add(self, player)
		end
	end

	return self
end, function(self: AllowanceService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
