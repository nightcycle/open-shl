--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local WeldUtil = require("@game/ReplicatedStorage/Shared/Util/Weld")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
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

function prepItemInst(id: string, item: Instance, isNotRoot: boolean?)
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

function newItemInst(item: Item): Result<Instance, string>
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
	return Result.ok(itemTemplateRes.Value:Clone())
end

function applyBasePart(definitionId: string, rig: Model, basePart: BasePart, isRoot: boolean): Result<true, string>
	local attachments = basePart:QueryDescendants("Attachment") :: { Attachment }
	if #attachments == 0 then
		return Result.err(`failed to find valid attachment under part`)
	elseif #attachments > 1 then
		return Result.err(`returned #{attachments} attachments, expected only one`)
	end
	local attachment = attachments[1]
	local anchor = getAnchorFromName(rig, attachment.Name)
	if not anchor then
		return Result.err(`attachment name "{attachment.Name}" couldn't be mapped into a valid anchor instance`)
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
	basePart:PivotTo(globalCF)
	prepItemInst(definitionId, basePart, not isRoot)
	WeldUtil.between(anchorPart, basePart)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end
function applyModel(definitionId: string, rig: Model, model: Model): Result<true, string>
	local root = model:FindFirstChild("root")
	if not root then
		return Result.err(`couldn't find root`)
	end
	if not root:IsA("BasePart") then
		return Result.err(`root wasn't BasePart`)
	end
	local attachments = root:QueryDescendants("Attachment") :: { Attachment }
	if #attachments == 0 then
		return Result.err(`failed to find valid attachment under part`)
	elseif #attachments > 1 then
		return Result.err(`returned #{attachments} attachments, expected only one`)
	end
	local attachment = attachments[1]
	local anchor = getAnchorFromName(rig, attachment.Name)
	if not anchor then
		return Result.err(`attachment name "{attachment.Name}" couldn't be mapped into a valid anchor instance`)
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
	model.WorldPivot = root.CFrame * root.PivotOffset
	model:PivotTo(globalCF)
	prepItemInst(definitionId, model)
	for i, v in model:QueryDescendants("BasePart") do
		WeldUtil.between(root, v)
	end
	WeldUtil.between(anchorPart, root)

	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- Modules
local Util = {}

function Util.apply(rig: Model, appearance: Appearance, item: Item): Result<true, string>
	local newItemRes = newItemInst(item)
	if newItemRes.IsErr then
		return newItemRes
	end
	local newItem = newItemRes.Value
	local applyResOpt: Option<Result<true, string>> = Option.none()
	if newItem:IsA("BasePart") then
		applyResOpt = Option.some(applyBasePart(item.DefinitionId, rig, newItem, true))
	elseif newItem:IsA("Model") then
		applyResOpt = Option.some(applyModel(item.DefinitionId, rig, newItem))
	elseif newItem:IsA("Folder") then
		for i, inst in newItem:GetChildren() do
			if inst:IsA("BasePart") then
				local applyChildRes = applyBasePart(item.DefinitionId, rig, inst, true)
				if applyChildRes.IsErr then
					applyResOpt = Option.some(applyChildRes)
					break
				end
			elseif inst:IsA("Model") then
				local applyChildRes = applyModel(item.DefinitionId, rig, inst)
				if applyChildRes.IsErr then
					applyResOpt = Option.some(applyChildRes)
					break
				end
			end
		end
		applyResOpt = Option.some(Result.ok(true :: any))
	end
	if applyResOpt.IsNone then
		return Result.err(`todo`)
	end
	local applyRes = applyResOpt.Value
	if applyRes.IsErr then
		newItem:Destroy()
	else
		newItem.Parent = rig
	end
	return applyRes
end
return Util
