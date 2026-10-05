--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local Locker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
-- Types
type Future<V, Progress...> = TypeUnionLib.Future<V, Progress...>
type ArtifactSceneImpl = {
	__index: ArtifactSceneImpl,
	RotateCharacter: (self: ArtifactScene, degrees: number) -> (),
	Load: (self: ArtifactScene, appearance: AppearanceType.Appearance) -> () -> (),
}
export type ArtifactScene = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Instance: Folder,
		_CameraMount: BasePart,
		_Rig: Future<Model>,
		_Rotation: number,
		_Appearance: AppearanceType.Appearance?,
		_Character: Model?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ArtifactSceneImpl
))
-- Constants
-- Variables
-- References
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/artifact-editor") :: Folder
-- Private Functions
-- Class
local ArtifactScene = {} :: ArtifactSceneImpl
ArtifactScene.__index = ArtifactScene

function ArtifactScene:RotateCharacter(degrees: number): () end

function ArtifactScene:Load(appearance: AppearanceType.Appearance): () -> ()
	return function() end
end

return Locker(function(): ArtifactScene
	local inst = SceneTemplate:Clone()
	local rigAnchor: BasePart = IndexUtil.waitForMatch(inst, function(desc: Instance): BasePart?
		if desc:IsA("BasePart") and desc.Name == "RigAnchor" then
			return desc
		end
		return nil
	end, nil, true, true)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Rotation = 0,
		_CameraMount = IndexUtil.waitForMatch(inst, function(desc: Instance): BasePart?
			if desc:IsA("BasePart") and desc.Name == "Cam" then
				return desc
			end
			return nil
		end, nil, true, true),
		_Rig = Future.toDo(function(getIfCanceled)
			local humDesc = Instance.new("HumanoidDescription")
			local avatar = Players:CreateHumanoidModelFromDescriptionAsync(
				humDesc,
				Enum.HumanoidRigType.R15,
				Enum.AssetTypeVerification.ClientOnly
			)
			if getIfCanceled() then
				avatar:Destroy()
			end
			avatar:PivotTo(rigAnchor.CFrame * CFrame.new(0, 2.5, 0))
			avatar.Parent = inst
			return avatar
		end),
		_Instance = inst,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ArtifactScene)
	return self
end, function(self: ArtifactScene)
	for i, v in self._Connections do
		v:Disconnect()
	end
	table.clear(self._CleanUpCallbacks)
	for i, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	if self._Rig.IsDoing then
		self._Rig = Future.cancel(self._Rig)
	end
	self._Instance:Destroy()
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
