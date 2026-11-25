--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local RideUtil = require("@self/Ride")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TelepadDefinition = require("@game/ServerScriptService/Server/Definition/Telepad")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
-- Types
type End = RideUtil.End<BasePart>
type TelepadServiceImpl = {
	__index: TelepadServiceImpl,
}
export type TelepadService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- when each carries somebody again, on the clock of os.clock. one that isn't in carries anybody
		_PadReadyAt: { [BasePart]: number },
		_RiderReadyAt: { [Player]: number },
		_Random: Random,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: TelepadServiceImpl
))
-- Constants
local LANDING: RideUtil.Landing = table.freeze({
	Rise = TelepadDefinition.RISE,
	Spread = TelepadDefinition.SPREAD,
	Facing = TelepadDefinition.FACING,
})
-- Variables
-- References
-- Private Functions
-- the ends the map marks with the tag, + what's wrong with the ones that don't say which pair they're of
local function list(tag: MapDefinition.Tag<BasePart>, faults: { string }): { End }
	local ends: { End } = {}
	for _, part in MapDefinition.list(tag) do
		local idRes = MapDefinition.get(part, MapDefinition.TelepadId)
		if idRes.IsOk then
			table.insert(ends, { Part = part, Id = idRes.Value })
		else
			table.insert(faults, idRes.Value)
		end
	end
	return ends
end

local function onTouched(self: TelepadService, pad: BasePart, exit: BasePart, hit: BasePart)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local player, character = TouchUtil.getToucher(hit)
	if not player or not character or SessionService:Get(player).IsNone then
		return
	end
	if
		AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
		or not TouchUtil.getIfNear(character, pad, TouchUtil.REACH)
	then
		return
	end
	local now = os.clock()
	if not RideUtil.getIfReady(now, self._PadReadyAt[pad], self._RiderReadyAt[player]) then
		return
	end
	-- the pivot of an avatar is its root
	character:PivotTo(RideUtil.getLanding(exit.CFrame, LANDING, self._Random))
	self._RiderReadyAt[player] = now + TelepadDefinition.ARRIVAL_IMMUNITY
	self._PadReadyAt[pad] = now + TelepadDefinition.PAD_COOLDOWN
end
-- Class
local TelepadService = {} :: TelepadServiceImpl
TelepadService.__index = TelepadService

-- the pads of the map: whoever steps on one stands at the exit of the same id. the server hears the touch + moves the
-- avatar, nobody is told + nothing is drawn. a side, a fight, being held: none of it is asked about
return ServiceLocker(function(): TelepadService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_PadReadyAt = {},
		_RiderReadyAt = {},
		_Random = Random.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, TelepadService)

	-- the server holds the whole map, whatever streaming does to a client
	local faults: { string } = {}
	local pads = list(MapDefinition.Telepad, faults)
	local exits = list(MapDefinition.TelepadExit, faults)
	local pairing = RideUtil.pair(pads, exits)
	table.move(pairing.Faults, 1, #pairing.Faults, #faults + 1, faults)
	if #faults > 0 and TelepadDefinition.IS_EXIT_REQUIRED then
		error(`the pads of the map: {table.concat(faults, ", ")}`)
	end
	for _, fault in faults do
		warn(`{fault}, it carries nobody`)
	end
	for _, note in pairing.Notes do
		warn(note)
	end

	for pad, exit in pairing.Exits do
		table.insert(
			self._Connections,
			pad.Touched:Connect(function(hit: BasePart)
				onTouched(self, pad, exit, hit)
			end)
		)
	end
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		self._RiderReadyAt[player] = nil
	end)
	table.insert(self._CleanUpCallbacks, function()
		removingConnection:Disconnect()
	end)

	return self
end, function(self: TelepadService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
