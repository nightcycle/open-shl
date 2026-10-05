--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
local WeldUtil = require("@game/ReplicatedStorage/Shared/Util/Weld")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type ItemDefinitionIndex = ItemAppearanceDefinition.ItemDefinitionIndex
-- Constants
local ITEM_TAG = "AppearanceItem"
-- Variables
-- References
-- Private Functions
function getAnchorFromName(rig: Model, name: string): (BasePart | Attachment)?
	local anchorPart = IndexUtil.findFirstMatch(rig, function(v: Instance): BasePart?
		if v:IsA("BasePart") and v.Name == name then
			return v
		end
		return nil
	end)
	if anchorPart then
		return anchorPart
	end
	local anchorAttachment = IndexUtil.findFirstMatch(rig, function(v: Instance): Attachment?
		if v:IsA("Attachment") and v.Name == name then
			return v
		end
		return nil
	end)
	return anchorAttachment
end
function prepItemInst(id: string, item: Instance, isNotRoot: true?)
	if item:IsA("BasePart") then
		item.CanCollide = false
		item.CanQuery = false
		item.CanTouch = false
		item.Anchored = false
	end
	for i, v in item:GetChildren() do
		prepItemInst(id, v, true)
	end
	if not isNotRoot then
		item:AddTag(ITEM_TAG)
		item.Name = id
	end
end
function applyItem(rig: Model, appearance: Appearance, item: Item): Result<true, string>
	local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
	if itemDefIndexRes.IsErr then
		return Result.err(`bad item def id: {itemDefIndexRes.Value}`)
	end
	local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
	if itemDefRes.IsErr then
		return Result.err(`item-def error: {itemDefRes.Value}`)
	end
	local itemTemplateRes = ItemAppearanceDefinition.getTemplate(item.DefinitionId)
	if itemTemplateRes.IsErr then
		return Result.err(`item-template error: {itemTemplateRes.Value}`)
	end
	local newItem = itemTemplateRes.Value:Clone()
	local function tryApply(): Result<true, string>
		if itemDefIndexRes.Value.Group == "costume" then
			if itemDefIndexRes.Value.Category == "artifacts" then
				if not newItem:IsA("BasePart") then
					return Result.err(`expected BasePart, received "{newItem.ClassName}"`)
				end
				local attachments = newItem:QueryDescendants("Attachment") :: { Attachment }
				if #attachments == 0 then
					return Result.err(`failed to find valid attachment under part`)
				elseif #attachments > 1 then
					return Result.err(`returned #{attachments} attachments, expected only one`)
				end
				local attachment = attachments[1]
				local anchor = getAnchorFromName(rig, attachment.Name)
				if not anchor then
					return Result.err(
						`attachment name "{attachment.Name}" couldn't be mapped into a valid anchor instance`
					)
				end
				local globalCF: CFrame
				local anchorPart: BasePart
				if anchor:IsA("Attachment") then
					local anchorParent = anchor:FindFirstAncestorWhichIsA("BasePart")
					if not anchorParent then
						return Result.err(`couldn't find basepart ancestor for root attachment "{attachment.Name}"`)
					end
					anchorPart = anchorPart
					globalCF = anchorParent.CFrame * anchor.CFrame
				else
					anchorPart = anchor
					globalCF = anchor.CFrame
				end
				globalCF *= attachment.CFrame:Inverse()
				newItem:PivotTo(globalCF)
				prepItemInst(item.DefinitionId, newItem)
				WeldUtil.between(anchorPart, newItem)
				newItem.Name = item.DefinitionId
				newItem.Parent = rig
				return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
			end
		end
		return Result.err(`todo`)
	end
	local applyRes = tryApply()
	if applyRes.IsErr then
		newItem:Destroy()
	end
	return applyRes
end
-- Class
local Util = {}

function Util.clear(rig: Model): TypeUnionLib.ToDo<true>
	return Future.toDo(function(getIfCanceled): true?
		local desc = HumanoidDescriptionBuilder.new():build()
		local f = Future.awaitUntil(RigUtil.applyDescription(rig, desc), getIfCanceled)
		desc:Destroy()
		for i, v in rig:QueryDescendants(`.{ITEM_TAG}`) do
			v:Destroy()
		end
		if f.IsDone then
			return true
		end
		return
	end)
end

function Util.apply(rig: Model, appearance: Appearance): TypeUnionLib.ToDo<Result<true, { string }>>
	return Future.toDo(function(getIfCanceled): Result<true, { string }>?
		do
			local f = Future.awaitUntil(Util.clear(rig), getIfCanceled)
			if f.IsCanceled then
				return
			end
		end
		local errs = {}
		for i, item in appearance.Items do
			if getIfCanceled() then
				return
			end
			local res = applyItem(rig, appearance, item)
			if res.IsErr then
				table.insert(errs, `item "{item.DefinitionId}" failed to apply: {res.Value}`)
			end
		end
		if #errs > 0 then
			return Result.err(errs)
		end
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end)
end

return Util
