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
-- Class
local Util = {}

Util.FAKE_HEAD_NAME = FAKE_HEAD_NAME

Util.moveTo = function(rig: Model, ground: CFrame): ()
	local description = rig:FindFirstChildWhichIsA("HumanoidDescription", true)
	rig:PivotTo(ground * CFrame.new(0, 2.5 * (description and description.HeightScale or 1), 0))
end

Util.createFromDescription = function(
	description: HumanoidDescription,
	ground: CFrame?,
	parent: Instance?,
	noEdits: true?
): TypeUnionLib.ToDo<Model>
	return Future.toDo(function(getIfCanceled)
		local avatar = Players:CreateHumanoidModelFromDescriptionAsync(
			description,
			Enum.HumanoidRigType.R15,
			Enum.AssetTypeVerification.ClientOnly
		)
		if getIfCanceled() then
			avatar:Destroy()
		end
		if noEdits then
			return avatar
		end

		local realHead: BasePart = IndexUtil.waitForMatch(avatar, function(v: Instance): BasePart?
			if v:IsA("BasePart") and v.Name == "Head" then
				return v
			end
			return nil
		end)
		realHead.Transparency = 1

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

		local _ = WeldUtil.weldTo(realHead, fakeHead)
		fakeHead.Parent = avatar

		if ground then
			Util.moveTo(avatar, ground)
		end
		if parent then
			avatar.Parent = parent
		end

		return avatar
	end)
end

return Util
