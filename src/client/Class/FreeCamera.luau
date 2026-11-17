--!strict
-- Services
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
-- Types
type FreeCameraImpl = {
	__index: FreeCameraImpl,
	Step: (self: FreeCamera, deltaTime: number) -> (),
	Destroy: (self: FreeCamera) -> (),
}
export type FreeCamera = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		_Position: Vector3, -- where the camera is headed, what's on screen trails behind
		_Yaw: number,
		_Pitch: number,
		_IsLooking: boolean,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: FreeCameraImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
local MOVE_SPEED = 36
local PRECISION_MULTIPLIER = 0.2
local LOOK_SENSITIVITY = 0.54 -- degrees per pixel
-- keeps the camera from flipping onto its back
local MAX_PITCH = math.rad(80)
local EASE_RATE = 2 -- e^-2 of the way to the target is left after a second
local PRECISION_ACTION_NAME = "FreeCameraPrecision"
-- Variables
-- References
-- Private Functions
local function getCFrame(position: Vector3, yaw: number, pitch: number): CFrame
	return CFrame.new(position) * CFrame.fromOrientation(pitch, yaw, 0)
end

local function getAxis(negative: Enum.KeyCode, positive: Enum.KeyCode): number
	if UserInputService:IsKeyDown(positive) then
		return 1
	elseif UserInputService:IsKeyDown(negative) then
		return -1
	end
	return 0
end
-- Class
local FreeCamera = {} :: FreeCameraImpl
FreeCamera.__index = FreeCamera

function FreeCamera:Step(deltaTime: number)
	if not self.IsAlive then
		return
	end
	local camera = Workspace.CurrentCamera
	-- whatever else reaches for the camera meanwhile doesn't get to keep it
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- the keys belong to the chat for as long as it's typed into
	if not UserInputService:GetFocusedTextBox() then
		local distance = MOVE_SPEED * deltaTime
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			distance *= PRECISION_MULTIPLIER
		end
		-- every axis is the camera's own, up + down included
		local offset = Vector3.new(
			getAxis(Enum.KeyCode.A, Enum.KeyCode.D),
			getAxis(Enum.KeyCode.Q, Enum.KeyCode.E),
			getAxis(Enum.KeyCode.W, Enum.KeyCode.S)
		) * distance
		self._Position = getCFrame(self._Position, self._Yaw, self._Pitch):PointToWorldSpace(offset)
	end

	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		local delta = UserInputService:GetMouseDelta()
		self._Yaw -= math.rad(delta.X * LOOK_SENSITIVITY)
		self._Pitch = math.clamp(self._Pitch - math.rad(delta.Y * LOOK_SENSITIVITY), -MAX_PITCH, MAX_PITCH)
		self._IsLooking = true
	elseif self._IsLooking then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		self._IsLooking = false
	end

	local target = getCFrame(self._Position, self._Yaw, self._Pitch)
	camera.CFrame = camera.CFrame:Lerp(target, 1 - math.exp(-EASE_RATE * deltaTime))
	-- the world is drawn in detail around the focus, it would stay behind with the avatar
	camera.Focus = camera.CFrame
end

function FreeCamera:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false :: any
	-- handed back first, so the camera is never left without anybody moving it
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	if self._IsLooking then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
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
	new = function(): FreeCamera
		local camera = Workspace.CurrentCamera
		-- the default camera doesn't roll, one that was tilted is flown on level
		local pitch, yaw = camera.CFrame:ToOrientation()
		local self = setmetatable({
			IsAlive = true :: true,
			_Position = camera.CFrame.Position,
			_Yaw = yaw,
			_Pitch = math.clamp(pitch, -MAX_PITCH, MAX_PITCH),
			_IsLooking = false,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, FreeCamera)

		-- left shift is also what turns the mouse lock of the default camera on + off, so it's kept from getting there
		ContextActionService:BindActionAtPriority(PRECISION_ACTION_NAME, function(): Enum.ContextActionResult
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftShift)
		table.insert(self._CleanUpCallbacks, function()
			ContextActionService:UnbindAction(PRECISION_ACTION_NAME)
		end)
		-- the camera is taken last, nothing above can leave it without anybody moving it
		camera.CameraType = Enum.CameraType.Scriptable

		return self
	end,
}
