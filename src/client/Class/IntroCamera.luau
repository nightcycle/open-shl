--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
local Result = TypeUnionLib.Result
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type ToDo<V, Progress...> = TypeUnionLib.ToDo<V, Progress...>
-- the last leg of the intro: from wherever the pan got to, to where the default camera takes over
type Flight = {
	StartTime: number,
	Origin: CFrame,
	Goal: CFrame,
}
type IntroCameraImpl = {
	__index: IntroCameraImpl,
	FlyTo: (self: IntroCamera, goal: CFrame) -> ToDo<true>,
	Destroy: (self: IntroCamera) -> (),
}
export type IntroCamera = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		_Origin: Vector3,
		_Goal: Vector3,
		_Focus: Vector3,
		_StartTime: number,
		_Flight: Flight?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: IntroCameraImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
local PAN_DURATION = 14
local FLY_DURATION = 1.5
-- the camera glides from the first way-point to the second + looks at the focus all the way
local ORIGIN_NAME = "1"
local GOAL_NAME = "2"
local FOCUS_NAME = "Focus"
-- Variables
-- References
-- Private Functions
local function getPosition(wayPoints: Instance, name: string): Result<Vector3, string>
	local wayPoint = wayPoints:FindFirstChild(name)
	if not wayPoint or not wayPoint:IsA("BasePart") then
		return Result.err(`no "{name}" way-point in {wayPoints:GetFullName()}`)
	end
	return Result.ok(wayPoint.Position)
end

local function step(self: IntroCamera)
	if not self.IsAlive then
		return
	end
	local camera = Workspace.CurrentCamera
	-- whatever else laid a hand on it in the meantime, the intro isn't done with it
	camera.CameraType = Enum.CameraType.Scriptable
	local flight = self._Flight
	if flight then
		local alpha = math.clamp((os.clock() - flight.StartTime) / FLY_DURATION, 0, 1)
		camera.CFrame = flight.Origin:Lerp(flight.Goal, alpha)
		camera.Focus = flight.Goal
	else
		local alpha = math.clamp((os.clock() - self._StartTime) / PAN_DURATION, 0, 1)
		camera.CFrame = CFrame.lookAt(self._Origin:Lerp(self._Goal, alpha), self._Focus)
		camera.Focus = CFrame.new(self._Focus)
	end
end
-- Class
local IntroCamera = {} :: IntroCameraImpl
IntroCamera.__index = IntroCamera

function IntroCamera:FlyTo(goal: CFrame): ToDo<true>
	return Future.toDo(function(getIfCanceled: () -> boolean): true?
		if not self.IsAlive then
			return nil
		end
		self._Flight = {
			StartTime = os.clock(),
			Origin = Workspace.CurrentCamera.CFrame,
			Goal = goal,
		}
		local finishTime = os.clock() + FLY_DURATION
		while os.clock() < finishTime do
			task.wait()
			if getIfCanceled() or not self.IsAlive then
				return nil
			end
		end
		return true
	end)
end

function IntroCamera:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false :: any
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

return {
	new = function(wayPoints: Instance): Result<IntroCamera, string>
		local originRes = getPosition(wayPoints, ORIGIN_NAME)
		if originRes.IsErr then
			return originRes
		end
		local goalRes = getPosition(wayPoints, GOAL_NAME)
		if goalRes.IsErr then
			return goalRes
		end
		local focusRes = getPosition(wayPoints, FOCUS_NAME)
		if focusRes.IsErr then
			return focusRes
		end
		local origin, goal, focus = originRes.Value, goalRes.Value, focusRes.Value
		-- a camera can't look at the spot it's on
		if origin:FuzzyEq(focus) or goal:FuzzyEq(focus) then
			return Result.err(`a way-point in {wayPoints:GetFullName()} sits on the focus`)
		end

		local self = setmetatable({
			IsAlive = true :: true,
			_Origin = origin,
			_Goal = goal,
			_Focus = focus,
			_StartTime = os.clock(),
			_Flight = nil :: Flight?,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, IntroCamera)

		table.insert(
			self._Connections,
			RunService.RenderStepped:Connect(function()
				step(self)
			end)
		)
		step(self)
		table.insert(self._CleanUpCallbacks, function()
			local camera = Workspace.CurrentCamera
			camera.CameraType = Enum.CameraType.Custom
			local character = Players.LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end)

		return Result.ok(self)
	end,
}
