--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Types
type Future<V, Progress...> = TypeUnionLib.Future<V, Progress...>
type SceneImpl = {
	__index: SceneImpl,
	Destroy: (self: Scene) -> (),
}
export type Scene = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		_HumanoidDescriptionTemplate: HumanoidDescription,
		Instance: Instance,
		CameraMount: BasePart,
		RigAnchor: BasePart,
		Rig: Future<Model>,
		_Rotation: number,
		_Character: Model?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SceneImpl
)) | {
	IsAlive: false,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Scene = {} :: SceneImpl
Scene.__index = Scene

function Scene:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false :: any
	for i, v in self._Connections do
		v:Disconnect()
	end
	table.clear(self._CleanUpCallbacks)
	for i, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	if self.Rig.IsDoing then
		self.Rig = Future.cancel(self.Rig)
	elseif self.Rig.IsDone then
		self.Rig.Value:Destroy()
	end
	self.Instance:Destroy()
	self._HumanoidDescriptionTemplate:Destroy()
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

return {
	new = function(sceneTemplate: Instance): Scene
		local inst = sceneTemplate:Clone()
		local rigAnchor: BasePart = IndexUtil.waitForMatch(inst, function(desc: Instance): BasePart?
			if desc:IsA("BasePart") and desc.Name == "RigAnchor" then
				return desc
			end
			return nil
		end, nil, true, true)
		local humDesc = HumanoidDescriptionBuilder.new():build()
		local self = setmetatable({
			IsAlive = true :: true,
			_Rotation = 0,
			_HumanoidDescriptionTemplate = humDesc,
			RigAnchor = rigAnchor,
			CameraMount = IndexUtil.waitForMatch(inst, function(desc: Instance): BasePart?
				if desc:IsA("BasePart") and desc.Name == "Cam" then
					return desc
				end
				return nil
			end, nil, true, true),
			Rig = RigUtil.createFromDescription(humDesc, rigAnchor.CFrame, inst),
			Instance = inst,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, Scene)
		return self
	end,
}
