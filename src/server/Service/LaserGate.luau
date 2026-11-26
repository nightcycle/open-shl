--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local HazardService = require("@game/ServerScriptService/Server/Service/Hazard")
local LaserGateDefinition = require("@game/ServerScriptService/Server/Definition/LaserGate")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
-- Types
-- the beams of one model, they go lit + dark together
type Grid = {
	Gates: { BasePart },
	Thread: thread?,
}
type LaserGateServiceImpl = {
	__index: LaserGateServiceImpl,
}
export type LaserGateService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Grids: { [Model]: Grid },
		-- whether players fight right now: no grid is lit while they don't
		_IsPVP: boolean,
		_Random: Random,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: LaserGateServiceImpl
))
-- Constants
-- what the old place made its beams of: a part of any other class under the model isn't one
local GATE_CLASS_NAME = "Part"
-- Variables
-- References
-- Private Functions
-- a lit beam is a wall that kills on touch, a dark one isn't there. the kill is the hazard service's: whatever
-- humanoid touches goes down the way the engine has anything die, in a menu or held as well
local function setLit(grid: Grid, isLit: boolean)
	assert(HazardService.IsInitialized, `the hazard service isn't initialized`)
	local look = if isLit then LaserGateDefinition.LIT else LaserGateDefinition.DARK
	for _, gate in grid.Gates do
		gate.Transparency = look.Transparency
		gate.CanCollide = look.CanCollide
		HazardService:SetLethal(gate, isLit)
	end
end

local function stop(grid: Grid)
	local thread = grid.Thread
	if thread and coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
	grid.Thread = nil
end

-- lit from the start, as the map has it, then dark + lit in turns for as long as each phase is rolled. where nobody
-- fights it's dark + stays so
local function start(self: LaserGateService, grid: Grid)
	stop(grid)
	setLit(grid, self._IsPVP)
	if not self._IsPVP then
		return
	end
	grid.Thread = task.spawn(function()
		local isLit = true
		while true do
			task.wait(LaserGateDefinition.rollDuration(self._Random))
			isLit = not isLit
			setLit(grid, isLit)
		end
	end)
end
-- Class
local LaserGateService = {} :: LaserGateServiceImpl
LaserGateService.__index = LaserGateService

-- the grids of the map: all beams of one blink on + off together, on a server's own roll. nobody is told + nothing
-- is drawn: two properties of every beam replicate at a flip. it's the town's guard against its villains but asks
-- nobody's side, + it's off wherever nobody fights: a server that changes its mind about that is followed at once
return ServiceLocker(function(): LaserGateService
	assert(HazardService.IsInitialized, `the hazard service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Grids = {} :: { [Model]: Grid },
		_IsPVP = ModeDefinition.getIfPVPEnabled(),
		_Random = Random.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, LaserGateService)

	local stopGrids = MapDefinition.observe(MapDefinition.LaserGate, function(model: Model): (() -> ())?
		local grid: Grid = {
			Gates = {},
		}
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") and child.ClassName == GATE_CLASS_NAME then
				table.insert(grid.Gates, child)
			end
		end
		self._Grids[model] = grid
		start(self, grid)
		return function()
			stop(grid)
			setLit(grid, false)
			self._Grids[model] = nil
		end
	end)
	-- told at once, which is what every grid already started by
	local stopMode = ModeDefinition.observe(function(isPVP: boolean)
		if isPVP == self._IsPVP then
			return
		end
		self._IsPVP = isPVP
		for _, grid in self._Grids do
			start(self, grid)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		stopMode()
		stopGrids()
	end)

	return self
end, function(self: LaserGateService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
