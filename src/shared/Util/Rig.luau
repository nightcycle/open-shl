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
local IN_PROGRESS_TAG = "IN_PROGRESS"
local FAKE_HEAD_NAME = "FAKE_HEAD"
local DATA_MODEL_TIMEOUT = 10
-- Variables
-- References
-- Private Functions
local function applyEdits(rig: Model, description: HumanoidDescription)
	local realHead: BasePart? = IndexUtil.findFirstMatch(rig, function(v: Instance): BasePart?
		if v:IsA("BasePart") and v.Name == "Head" then
			return v
		end
		return nil
	end)
	if not realHead then
		warn(`rig "{rig.Name}" has no head to edit`)
		return
	end
	realHead.Transparency = 1
	-- a decal still renders on an invisible part, the stock face would show through
	for _, v in realHead:GetChildren() do
		if v:IsA("Decal") then
			v.Transparency = 1
		end
	end

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
	fakeHead.Massless = true
	fakeHead.Size = Vector3.one * description.HeadScale
	fakeHead.CFrame = realHead.CFrame
	-- the description is read instead of the real head, the body colors may not have reached the parts yet
	fakeHead.Color = description.HeadColor
	fakeHead.Material = realHead.Material

	local fakeHeadMesh = Instance.new("SpecialMesh")
	fakeHeadMesh.MeshType = Enum.MeshType.Head
	fakeHeadMesh.Scale = Vector3.one * 1.25
	fakeHeadMesh.Parent = fakeHead

	local _ = WeldUtil.between(realHead, fakeHead)
	fakeHead.Parent = rig
end

local function tryEdits(rig: Model, description: HumanoidDescription)
	local success, msg = pcall(function()
		applyEdits(rig, description)
	end)
	if not success then
		warn(`rig "{rig.Name}" failed to edit: {msg}`)
	end
end

local function tryDescription(humanoid: Humanoid, description: HumanoidDescription): (boolean, string?)
	local success, msg = pcall(function()
		humanoid:ApplyDescriptionResetAsync(description, Enum.AssetTypeVerification.ClientOnly)
	end)
	return success, if success then nil else tostring(msg)
end
-- Class
local Util = {}

Util.FAKE_HEAD_NAME = FAKE_HEAD_NAME

Util.moveTo = function(rig: Model, ground: CFrame): ()
	local description = rig:FindFirstChildWhichIsA("HumanoidDescription", true)
	rig:PivotTo(ground * CFrame.new(0, 2.5 * (description and description.HeightScale or 1), 0))
end

Util.applyDescription = function(rig: Model, description: HumanoidDescription, noEdits: true?): TypeUnionLib.ToDo<Model>
	return Future.toDo(function(getIfCanceled): Model?
		local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			return nil
		end
		do
			while humanoid:HasTag(IN_PROGRESS_TAG) do
				if getIfCanceled() then
					return nil
				end
				task.wait()
			end

			humanoid:AddTag(IN_PROGRESS_TAG)
			local success, msg = tryDescription(humanoid, description)
			if not success and not rig:IsDescendantOf(game) then
				-- a humanoid can't take a description outside of the DataModel,
				-- a fresh character or scene rig only gets parented a moment after it's handed out
				local startTime = os.clock()
				while
					not rig:IsDescendantOf(game)
					and not getIfCanceled()
					and os.clock() - startTime < DATA_MODEL_TIMEOUT
				do
					task.wait()
				end
				if rig:IsDescendantOf(game) and not getIfCanceled() then
					success, msg = tryDescription(humanoid, description)
				end
			end
			humanoid:RemoveTag(IN_PROGRESS_TAG)
			if getIfCanceled() then
				return nil
			end
			if not success then
				warn(msg)
			end
		end

		if not noEdits then
			tryEdits(rig, description)
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
	return Future.toDo(function(getIfCanceled): Model?
		-- the request can fail + the parent can be gone by the time it's back
		local success, rig = pcall(function(): Model?
			local newRig = Players:CreateHumanoidModelFromDescriptionAsync(
				description,
				Enum.HumanoidRigType.R15,
				Enum.AssetTypeVerification.ClientOnly
			)
			if getIfCanceled() then
				newRig:Destroy()
				return nil
			end
			if not noEdits then
				applyEdits(newRig, description)
			end

			if ground then
				Util.moveTo(newRig, ground)
			end
			if parent then
				newRig.Parent = parent
			end

			return newRig
		end)
		if not success then
			warn(rig)
			return nil
		end

		return rig
	end)
end

return Util
