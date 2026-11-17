--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local FreeCamera = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/FreeCamera")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local WalkLock = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/WalkLock")
-- Types
type FreeCamera = FreeCamera.FreeCamera
type WalkLock = WalkLock.WalkLock
-- the avatar can't walk or turn while the camera is flown
type Hold = {
	Humanoid: Humanoid,
	WalkLock: WalkLock,
	IsAutoRotating: boolean,
	Connections: { RBXScriptConnection },
}
type CameraModeServiceImpl = {
	__index: CameraModeServiceImpl,
}
export type CameraModeService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_FreeCamera: FreeCamera?, -- only while the camera is flown
		_StepConnection: RBXScriptConnection?,
		_Hold: Hold?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: CameraModeServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function getHumanoid(): Humanoid?
	local avatar = Players.LocalPlayer.Character
	return avatar and avatar:FindFirstChildOfClass("Humanoid")
end

local function release(self: CameraModeService)
	local current = self._Hold
	if not current then
		return
	end
	self._Hold = nil
	for _, v in current.Connections do
		v:Disconnect()
	end
	local walkLock = current.WalkLock
	if walkLock.IsAlive then
		walkLock:Destroy()
	end
	local humanoid = current.Humanoid
	if not humanoid.AutoRotate then
		humanoid.AutoRotate = current.IsAutoRotating
	end
end

-- the keys that fly the camera are the ones that walk, so the avatar is kept from turning after them. it can still jump
local function hold(self: CameraModeService, humanoid: Humanoid)
	release(self)
	local newHold: Hold = {
		Humanoid = humanoid,
		WalkLock = WalkLock.new(humanoid),
		IsAutoRotating = humanoid.AutoRotate,
		Connections = {},
	}
	self._Hold = newHold
	humanoid.AutoRotate = false
	table.insert(
		newHold.Connections,
		humanoid:GetPropertyChangedSignal("AutoRotate"):Connect(function()
			if humanoid.AutoRotate then
				newHold.IsAutoRotating = true
				humanoid.AutoRotate = false
			end
		end)
	)
end

local function exit(self: CameraModeService)
	local stepConnection = self._StepConnection
	if stepConnection then
		self._StepConnection = nil
		stepConnection:Disconnect()
	end
	local freeCamera = self._FreeCamera
	self._FreeCamera = nil
	if freeCamera and freeCamera.IsAlive then
		freeCamera:Destroy()
		local humanoid = getHumanoid()
		if humanoid then
			Workspace.CurrentCamera.CameraSubject = humanoid
		end
	end
	release(self)
end

-- the mode is the shell's to end
local function finish(self: CameraModeService)
	if ShellService.IsInitialized and ShellService:GetIsCameraMode() then
		ShellService:SetCameraMode(false)
	end
	exit(self)
end

local function enter(self: CameraModeService)
	if self._FreeCamera then
		return
	end
	local humanoid = getHumanoid()
	if not humanoid then
		-- no avatar to fly away from. the shell is in the middle of saying the mode is on, so it's told right after
		task.defer(function()
			if self.IsInitialized and not self._FreeCamera then
				finish(self)
			end
		end)
		return
	end
	hold(self, humanoid)
	local freeCamera = FreeCamera.new()
	self._FreeCamera = freeCamera
	self._StepConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
		if freeCamera.IsAlive then
			freeCamera:Step(deltaTime)
		end
	end)
end
-- Class
local CameraModeService = {} :: CameraModeServiceImpl
CameraModeService.__index = CameraModeService

return ServiceLocker(function(): CameraModeService
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local player = Players.LocalPlayer

	local self = setmetatable({
		IsInitialized = true :: true,
		_FreeCamera = nil :: FreeCamera?,
		_StepConnection = nil :: RBXScriptConnection?,
		_Hold = nil :: Hold?,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, CameraModeService)

	local modeConnection = ShellService.CameraModeChanged:Connect(function(isCameraMode: boolean)
		if isCameraMode then
			enter(self)
		else
			exit(self)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		modeConnection:Disconnect()
	end)
	-- the avatar the camera flew away from is gone, the next one starts out with the camera behind it
	table.insert(
		self._Connections,
		player.CharacterRemoving:Connect(function()
			finish(self)
		end)
	)
	table.insert(
		self._Connections,
		player.CharacterAdded:Connect(function()
			finish(self)
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		finish(self)
	end)

	if ShellService:GetIsCameraMode() then
		enter(self)
	end

	return self
end, function(self: CameraModeService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
