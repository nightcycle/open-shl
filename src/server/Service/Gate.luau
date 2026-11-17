--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GateDefinition = require("@game/ServerScriptService/Server/Definition/Gate")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type GateDefinition = GateDefinition.GateDefinition
type Gate = {
	Definition: GateDefinition,
	Button: BasePart,
	Door: PVInstance,
	ClosedPivot: CFrame,
	OpenPivot: CFrame,
	IsOpen: boolean,
	IsBusy: boolean, -- a press is still being carried out, the button is dead until it's through
}
type GateServiceImpl = {
	__index: GateServiceImpl,
}
export type GateService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: GateServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function newGate(model: Model): Result<Gate, string>
	local idRes = MapDefinition.get(model, MapDefinition.GateId)
	if idRes.IsErr then
		return Result.err(idRes.Value)
	end
	local definitionRes = GateDefinition.get(idRes.Value)
	if definitionRes.IsErr then
		return Result.err(`{model:GetFullName()}: {definitionRes.Value}`)
	end
	local definition = definitionRes.Value
	local button = model:FindFirstChild(GateDefinition.BUTTON_NAME)
	local door = model:FindFirstChild(definition.DoorName)
	if not button or not button:IsA("BasePart") then
		return Result.err(`{model:GetFullName()} has no button`)
	end
	if not door or not door:IsA("PVInstance") then
		return Result.err(`{model:GetFullName()} has no "{definition.DoorName}" to move`)
	end
	local closedPivot = door:GetPivot()
	return Result.ok({
		Definition = definition,
		Button = button,
		Door = door,
		ClosedPivot = closedPivot,
		OpenPivot = if definition.Type == "Slide"
			then closedPivot + definition.Offset
			else closedPivot * CFrame.Angles(0, 0, math.rad(definition.Angle)),
		IsOpen = false,
		IsBusy = false,
	})
end

-- yields. the door ends up exactly on its pivot, however often it went back + forth before
local function move(gate: Gate, isOpen: boolean)
	local from = gate.Door:GetPivot()
	local to = if isOpen then gate.OpenPivot else gate.ClosedPivot
	local startTime = os.clock()
	local alpha = 0
	while alpha < 1 do
		task.wait()
		alpha = math.min((os.clock() - startTime) / gate.Definition.Duration, 1)
		gate.Door:PivotTo(if alpha < 1 then from:Lerp(to, alpha) else to)
	end
	gate.IsOpen = isOpen
end

-- yields until the gate takes the next press
local function press(gate: Gate)
	local definition = gate.Definition
	gate.IsBusy = true
	if definition.Type == "Slide" then
		local isOpen = not gate.IsOpen
		gate.Button.BrickColor = if isOpen then definition.OpenColor else definition.ClosedColor
		move(gate, isOpen)
		task.wait(definition.Cooldown)
	else
		gate.Button.Material = definition.BusyMaterial
		move(gate, true)
		task.wait(definition.HoldDuration)
		move(gate, false)
		task.wait(definition.Cooldown)
		gate.Button.Material = definition.ReadyMaterial
	end
	gate.IsBusy = false
end
-- Class
local GateService = {} :: GateServiceImpl
GateService.__index = GateService

return ServiceLocker(function(): GateService
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, GateService)

	for _, model in MapDefinition.list(MapDefinition.Gate) do
		local gateRes = newGate(model)
		if gateRes.IsErr then
			warn(`gate err: {gateRes.Value}`)
			continue
		end
		local gate = gateRes.Value
		table.insert(
			self._Connections,
			gate.Button.Touched:Connect(function(hit: BasePart)
				-- only somebody stepping on the button works it, not whatever happens to roll onto it
				if gate.IsBusy or not hit.Parent or not hit.Parent:FindFirstChildOfClass("Humanoid") then
					return
				end
				press(gate)
			end)
		)
	end

	return self
end, function(self: GateService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
