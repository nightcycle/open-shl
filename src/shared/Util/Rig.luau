--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
local WeldUtil = require("@game/ReplicatedStorage/Shared/Util/Weld")
-- Types
-- Constants
local FAKE_HEAD_NAME = "FAKE_HEAD"
-- Variables
-- References
-- Private Functions
function applyEdits(rig: Model, description: HumanoidDescription)
	local realHead: BasePart = IndexUtil.waitForMatch(rig, function(v: Instance): BasePart?
		if v:IsA("BasePart") and v.Name == "Head" then
			return v
		end
		return nil
	end)
	realHead.Transparency = 1

	do
		local priorFakeHead = rig:FindFirstChild(FAKE_HEAD_NAME)
		if priorFakeHead then
			priorFakeHead:Destroy()
		end
	end

	local fakeHead = Instance.new("Part")
	fakeHead.Name = FAKE_HEAD_NAME
	fakeHead.CanCollide = false
	fakeHead.CanQuery = false
	fakeHead.CanTouch = false
	fakeHead.Anchored = false
	fakeHead.Size = Vector3.one * description.HeadScale
	fakeHead.CFrame = realHead.CFrame
	fakeHead.Color = realHead.Color
	fakeHead.Material = realHead.Material

	local fakeHeadMesh = Instance.new("SpecialMesh")
	fakeHeadMesh.MeshType = Enum.MeshType.Head
	fakeHeadMesh.Scale = Vector3.one * 1.25
	fakeHeadMesh.Parent = fakeHead

	local _ = WeldUtil.between(realHead, fakeHead)
	fakeHead.Parent = rig
end
-- Class
local Util = {}

Util.FAKE_HEAD_NAME = FAKE_HEAD_NAME

Util.moveTo = function(rig: Model, ground: CFrame): ()
	local description = rig:FindFirstChildWhichIsA("HumanoidDescription", true)
	rig:PivotTo(ground * CFrame.new(0, 2.5 * (description and description.HeightScale or 1), 0))
end

Util.applyDescription = function(rig: Model, description: HumanoidDescription, noEdits: true?): TypeUnionLib.ToDo<Model>
	return Future.toDo(function(getIfCanceled)
		local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			return
		end

		humanoid:ApplyDescriptionResetAsync(description, Enum.AssetTypeVerification.ClientOnly)

		if not noEdits then
			applyEdits(rig, description)
		end

		return rig
	end)
end

Util.createFromDescription = function(
	description: HumanoidDescription,
	ground: CFrame?,
	parent: Instance?,
	noEdits: true?
): TypeUnionLib.ToDo<Model>
	return Future.toDo(function(getIfCanceled)
		local rig = Players:CreateHumanoidModelFromDescriptionAsync(
			description,
			Enum.HumanoidRigType.R15,
			Enum.AssetTypeVerification.ClientOnly
		)
		if getIfCanceled() then
			rig:Destroy()
		end
		if not noEdits then
			applyEdits(rig, description)
		end

		if ground then
			Util.moveTo(rig, ground)
		end
		if parent then
			rig.Parent = parent
		end

		return rig
	end)
end

return Util
