--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type BeaconServiceImpl = {
	__index: BeaconServiceImpl,
}
export type BeaconService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: BeaconServiceImpl
))
-- Constants
local DEFAULT_CYCLE_LENGTH = 2
local LIT_MATERIAL = Enum.Material.Neon
local UNLIT_MATERIAL = Enum.Material.SmoothPlastic
-- Variables
-- References
-- Private Functions
local function setMaterial(beacons: { BasePart }, material: Enum.Material)
	for _, beacon in beacons do
		beacon.Material = material
	end
end

-- yields for as long as the service lives. a beacon is lit for half of its cycle length + dark for all of it
local function blink(beacons: { BasePart }, cycleLength: number)
	while true do
		setMaterial(beacons, LIT_MATERIAL)
		task.wait(cycleLength / 2)
		setMaterial(beacons, UNLIT_MATERIAL)
		task.wait(cycleLength)
	end
end
-- Class
local BeaconService = {} :: BeaconServiceImpl
BeaconService.__index = BeaconService

return ServiceLocker(function(): BeaconService
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, BeaconService)

	-- the beacons of a cycle length share a thread, so they stay in step with one another
	local groups: { [number]: { BasePart } } = {}
	for _, beacon in MapDefinition.list(MapDefinition.Beacon) do
		local cycleLengthRes = MapDefinition.get(beacon, MapDefinition.CycleLength)
		if cycleLengthRes.IsErr then
			warn(`beacon err: {cycleLengthRes.Value}`)
			continue
		end
		local cycleLength = cycleLengthRes.Value or DEFAULT_CYCLE_LENGTH
		local group = groups[cycleLength]
		if not group then
			group = {}
			groups[cycleLength] = group
		end
		table.insert(group, beacon)
	end
	for cycleLength, beacons in groups do
		local thread = task.spawn(blink, beacons, cycleLength)
		table.insert(self._CleanUpCallbacks, function()
			task.cancel(thread)
		end)
	end

	return self
end, function(self: BeaconService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
