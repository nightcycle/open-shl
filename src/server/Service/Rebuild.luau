--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type Rebuilt = {
	Template: Model, -- how it stood when the server started
	Live: Model,
	Parent: Instance,
}
type RebuildServiceImpl = {
	__index: RebuildServiceImpl,
}
export type RebuildService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Rebuilts: { Rebuilt },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: RebuildServiceImpl
))
-- Constants
local REBUILD_INTERVAL = 120
-- Variables
-- References
-- Private Functions
-- yields for as long as the service lives
local function run(self: RebuildService)
	while true do
		task.wait(REBUILD_INTERVAL)
		for _, rebuilt in self._Rebuilts do
			-- swapped out whole, there's no telling which of its parts were knocked out of place
			rebuilt.Live:Destroy()
			rebuilt.Live = rebuilt.Template:Clone()
			rebuilt.Live.Parent = rebuilt.Parent
		end
	end
end
-- Class
local RebuildService = {} :: RebuildServiceImpl
RebuildService.__index = RebuildService

return ServiceLocker(function(): RebuildService
	local self = setmetatable({
		IsInitialized = true :: true,
		_Rebuilts = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, RebuildService)

	for _, model in MapDefinition.list(MapDefinition.Rebuilt) do
		if not model.Parent then
			continue
		end
		table.insert(self._Rebuilts, {
			Template = model:Clone(),
			Live = model,
			Parent = model.Parent,
		})
	end

	local thread = task.spawn(run, self)
	table.insert(self._CleanUpCallbacks, function()
		task.cancel(thread)
		for _, rebuilt in self._Rebuilts do
			rebuilt.Template:Destroy()
		end
	end)

	return self
end, function(self: RebuildService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
