--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
-- Types
type Future<V, Progress...> = TypeUnionLib.Future<V, Progress...>
type ArtifactSceneImpl = {
	__index: ArtifactSceneImpl,
	RotateCharacter: (self: ArtifactScene, degrees: number) -> (),
	Destroy: (self: ArtifactScene) -> (),
	Load: (self: ArtifactScene, appearance: AppearanceType.Appearance) -> () -> (),
}
export type ArtifactScene = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		_HumanoidDescriptionTemplate: HumanoidDescription,
		Instance: Folder,
		CameraMount: BasePart,
		Rig: Future<Model>,
		_Rotation: number,
		_Appearance: AppearanceType.Appearance?,
		_Character: Model?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ArtifactSceneImpl
)) | {
	IsAlive: nil,
}
-- Constants
-- Variables
-- References
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/artifact-editor") :: Folder
-- Private Functions
-- Class
local ArtifactScene = {} :: ArtifactSceneImpl
ArtifactScene.__index = ArtifactScene

function ArtifactScene:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = nil :: any
	for i, v in self._Connections do
		v:Disconnect()
	end
	table.clear(self._CleanUpCallbacks)
	for i, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	if self.Rig.IsDoing then
		self.Rig = Future.cancel(self.Rig)
	end
	self.Instance:Destroy()
	self._HumanoidDescriptionTemplate:Destroy()
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

function ArtifactScene:RotateCharacter(degrees: number): () end

function ArtifactScene:Load(appearance: AppearanceType.Appearance): () -> ()
	return function() end
end

return {
	new = function(): ArtifactScene
		local inst = SceneTemplate:Clone()
		local rigAnchor: BasePart = IndexUtil.waitForMatch(inst, function(desc: Instance): BasePart?
			if desc:IsA("BasePart") and desc.Name == "RigAnchor" then
				return desc
			end
			return nil
		end, nil, true, true)
		local humDesc =
			HumanoidDescriptionBuilder.new():addBodyColor(Color3.fromHSV(0, 0, 0.5)):setUseAvatarSettings(false):build()
		local self = setmetatable({
			IsAlive = true :: true,
			_Rotation = 0,
			_HumanoidDescriptionTemplate = humDesc,
			CameraMount = IndexUtil.waitForMatch(inst, function(desc: Instance): BasePart?
				if desc:IsA("BasePart") and desc.Name == "Cam" then
					return desc
				end
				return nil
			end, nil, true, true),
			Rig = Future.toDo(function(getIfCanceled)
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
			Instance = inst,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, ArtifactScene)
		return self
	end,
}
