--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
-- Types
-- a part that turns for show
type Spinner = {
	CFrame: CFrame, -- where the map has it, which is how it comes in every time it does
	Axis: Vector3, -- of its own
	Rate: number, -- radians a second, signed
}
type SceneryServiceImpl = {
	__index: SceneryServiceImpl,
}
export type SceneryService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Spinners: { [BasePart]: Spinner },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SceneryServiceImpl
))
-- Constants
local AXES = table.freeze({
	X = Vector3.xAxis,
	Y = Vector3.yAxis,
	Z = Vector3.zAxis,
})
local TURN = 2 * math.pi
-- Variables
-- References
-- Private Functions
-- how far a part is turned is read off the clock of the server, never added up: every client has it at the same
-- angle, + one that comes back in is where it would have been
local function step(self: SceneryService)
	local now = Workspace:GetServerTimeNow()
	for part, spinner in self._Spinners do
		-- the clock is in the billions of seconds, the whole turns come off while it's still a number that holds them
		local angle = (spinner.Rate * now) % TURN
		part.CFrame = spinner.CFrame * CFrame.fromAxisAngle(spinner.Axis, angle)
	end
end

local function add(self: SceneryService, part: BasePart): (() -> ())?
	local axisRes = MapDefinition.get(part, MapDefinition.SpinAxis)
	local rateRes = MapDefinition.get(part, MapDefinition.SpinRate)
	-- one that's marked wrong says so + stays as the map has it
	if axisRes.IsErr then
		warn(axisRes.Value)
		return nil
	elseif rateRes.IsErr then
		warn(rateRes.Value)
		return nil
	end
	local spinner: Spinner = {
		CFrame = part.CFrame,
		Axis = AXES[axisRes.Value],
		Rate = rateRes.Value,
	}
	self._Spinners[part] = spinner
	return function()
		self._Spinners[part] = nil
		part.CFrame = spinner.CFrame
	end
end
-- Class
local SceneryService = {} :: SceneryServiceImpl
SceneryService.__index = SceneryService

-- the parts of a map that only turn: a globe, the spouts of a fountain. they're anchored + the server never moves
-- them, so each client turns the ones it has by itself + nothing of it goes anywhere. what a click or a seat does
-- is everybody's to see, that's the server's
return ServiceLocker(function(): SceneryService
	local self = setmetatable({
		IsInitialized = true :: true,
		_Spinners = {} :: { [BasePart]: Spinner },
		_CleanUpCallbacks = {},
		_Connections = {},
	}, SceneryService)

	-- under streaming a part comes + goes
	local unobserve = MapDefinition.observe(MapDefinition.Spin, function(part: BasePart): (() -> ())?
		return add(self, part)
	end)
	table.insert(self._CleanUpCallbacks, unobserve)
	table.insert(
		self._Connections,
		RunService.RenderStepped:Connect(function()
			step(self)
		end)
	)

	return self
end, function(self: SceneryService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
