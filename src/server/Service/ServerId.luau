--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
local ServerRegistryUtil = require("@game/ServerScriptService/Server/Util/ServerRegistry")
-- Types
local RegistryType = require("@game/ServerScriptService/Server/Type/Registry")
type PublicServer = RegistryType.PublicServer
type ServerIdServiceImpl = {
	__index: ServerIdServiceImpl,
}
export type ServerIdService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ServerIdServiceImpl
))
-- Constants
-- a private server isn't for whoever happens to know its id + a studio session has no job to send anybody to
local IS_PUBLIC = game.PrivateServerId == "" and game.JobId ~= ""
local RENEW_INTERVAL = 60
-- a server that crashed is forgotten after this long, one that only missed a renewal or two isn't
local EXPIRY = 180
-- Variables
-- References
-- Private Functions
-- yields for as long as the service lives
local function run(server: PublicServer)
	local isFailing = false
	while true do
		local res = ServerRegistryUtil.setPublicServer(server, EXPIRY)
		-- a memory store that's down is told about once, not with every renewal it turns down
		if res.IsErr and not isFailing then
			warn(`server id err: {res.Value}`)
		end
		isFailing = res.IsErr
		task.wait(RENEW_INTERVAL)
	end
end
-- Class
local ServerIdService = {} :: ServerIdServiceImpl
ServerIdService.__index = ServerIdService

return ServiceLocker(function(): ServerIdService
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ServerIdService)

	if IS_PUBLIC then
		local server: PublicServer = table.freeze({
			PlaceId = game.PlaceId,
			JobId = game.JobId,
		})
		local renewThread = task.spawn(run, server)
		table.insert(self._CleanUpCallbacks, function()
			task.cancel(renewThread)
			-- a closing server isn't held up for this, a record that's left behind runs out by itself
			ServerRegistryUtil.removePublicServer(ServerDefinition.getId(server.JobId))
		end)
	end

	return self
end, function(self: ServerIdService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
