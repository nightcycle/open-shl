--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AlertService = require("@game/ServerScriptService/Server/Service/Alert")
local DisasterRunner = require("@self/Disaster")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
type CrimeServiceImpl = {
	__index: CrimeServiceImpl,
}
export type CrimeService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Disasters: DisasterRunner.Runner,
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

-- what the villains of a town do to it for money, + what the town has against them. each kind of crime is a child
-- that runs by itself from when it's made until it's destroyed: the disasters are the first, the bank is the next.
-- all of it pays through the economy, tells the heroes through the alert service + lands nothing where nobody fights
return ServiceLocker(function(): CrimeService
	assert(AlertService.IsInitialized, `the alert service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Disasters = DisasterRunner.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, CrimeService)

	table.insert(self._CleanUpCallbacks, self._Disasters.Destroy)

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
