--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type FlyInCameraImpl = {
	__index: FlyInCameraImpl,
	Destroy: (self: FlyInCamera) -> (),
}
export type FlyInCamera = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		-- seconds from when it was made to when it's where it flies to
		Duration: number,
		_Origin: Vector3,
		_Goal: Vector3,
		_Focus: Vector3,
		_StartTime: number,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: FlyInCameraImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
-- where the flight starts. it names the stop it's flown to, which says how fast
local ORIGIN_NAME = "StartCam"
local GOAL_VALUE_NAME = "NextCamera"
local SPEED_VALUE_NAME = "Speed"
-- the camera looks at the spot this far ahead of where it starts, all the way
local FOCUS_DISTANCE = 1000
-- a flight takes this many times what its length at its speed comes to
local DURATION_SCALE = 1.2
-- the view narrows as it goes
local ORIGIN_FIELD_OF_VIEW = 70
local GOAL_FIELD_OF_VIEW = 25
-- what the avatar's camera is handed back with
local DEFAULT_FIELD_OF_VIEW = 70
-- Variables
-- References
-- Private Functions
local function step(self: FlyInCamera)
	if not self.IsAlive then
		return
	end
	local camera = Workspace.CurrentCamera
	-- whatever else laid a hand on it in the meantime, the flight isn't done with it
	camera.CameraType = Enum.CameraType.Scriptable
	local alpha = math.clamp((os.clock() - self._StartTime) / self.Duration, 0, 1)
	camera.CFrame = CFrame.lookAt(self._Origin:Lerp(self._Goal, alpha), self._Focus)
	camera.Focus = CFrame.new(self._Focus)
	local zoomAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	camera.FieldOfView = ORIGIN_FIELD_OF_VIEW + (GOAL_FIELD_OF_VIEW - ORIGIN_FIELD_OF_VIEW) * zoomAlpha
end
-- Class
local FlyInCamera = {} :: FlyInCameraImpl
FlyInCamera.__index = FlyInCamera

function FlyInCamera:Destroy()
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
	-- a straight flight from one stop of the map to the next, the view pulls in on what's ahead of the first
	new = function(wayPoints: Instance): Result<FlyInCamera, string>
		local origin = wayPoints:FindFirstChild(ORIGIN_NAME)
		if not origin or not origin:IsA("BasePart") then
			return Result.err(`no "{ORIGIN_NAME}" way-point in {wayPoints:GetFullName()}`)
		end
		local goalValue = origin:FindFirstChild(GOAL_VALUE_NAME)
		local goal = if goalValue and goalValue:IsA("ObjectValue") then goalValue.Value else nil
		if not goal or not goal:IsA("BasePart") then
			return Result.err(`{origin:GetFullName()} names no way-point in "{GOAL_VALUE_NAME}"`)
		end
		local speedValue = goal:FindFirstChild(SPEED_VALUE_NAME)
		local speed = if speedValue and speedValue:IsA("NumberValue") then speedValue.Value else nil
		if not speed or speed <= 0 then
			return Result.err(`{goal:GetFullName()} has no "{SPEED_VALUE_NAME}" to be flown to at`)
		end
		local distance = (origin.Position - goal.Position).Magnitude
		-- a flight that goes nowhere would be over before it's seen
		if distance == 0 then
			return Result.err(`the way-points in {wayPoints:GetFullName()} sit on one spot`)
		end
		local focus = (origin.CFrame * CFrame.new(0, 0, -FOCUS_DISTANCE)).Position
		-- a camera can't look at the spot it's on
		if goal.Position:FuzzyEq(focus) then
			return Result.err(`{goal:GetFullName()} sits on what the flight looks at`)
		end

		local self = setmetatable({
			IsAlive = true :: true,
			Duration = DURATION_SCALE * distance / speed,
			_Origin = origin.Position,
			_Goal = goal.Position,
			_Focus = focus,
			_StartTime = os.clock(),
			_CleanUpCallbacks = {},
			_Connections = {},
		}, FlyInCamera)

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
			camera.FieldOfView = DEFAULT_FIELD_OF_VIEW
			local character = Players.LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end)

		return Result.ok(self)
	end,
}
