--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local BankDrawer = require("@self/Bank")
local DisasterDrawer = require("@self/Disaster")
-- Types
type CrimeServiceImpl = {
	__index: CrimeServiceImpl,
}
export type CrimeService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Disasters: DisasterDrawer.Drawer,
		_Bank: BankDrawer.Drawer,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: CrimeServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local CrimeService = {} :: CrimeServiceImpl
CrimeService.__index = CrimeService

-- what a client draws of the crimes of a town, each kind by a child that draws from when it's made until it's
-- destroyed: the disasters are one, the bank is the other. the server runs all of it + asks this client nothing
return ServiceLocker(function(): CrimeService
	local self = setmetatable({
		IsInitialized = true :: true,
		_Disasters = DisasterDrawer.new(),
		_Bank = BankDrawer.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, CrimeService)

	table.insert(self._CleanUpCallbacks, self._Disasters.Destroy)
	table.insert(self._CleanUpCallbacks, self._Bank.Destroy)

	return self
end, function(self: CrimeService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
