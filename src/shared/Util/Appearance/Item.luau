--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PatternDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Pattern")
local WeldUtil = require("@game/ReplicatedStorage/Shared/Util/Weld")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
export type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type TextureGroup = AppearanceType.TextureGroup
type HiddenTag = AppearanceType.HiddenTag
type Glow = {
	Range: number,
	Brightness: number,
	Shadows: boolean,
}
-- Constants
local ITEM_TAG = "AppearanceItem"
local PATTERN_NAME = "Pattern"
local GLOW_NAME = "Glow"
-- a pattern is one image stretched over each side of a part
local PATTERN_FACES: { Enum.NormalId } = table.freeze(Enum.NormalId:GetEnumItems())
-- where neon lights what's around it, a part of that material carries a light of its own color
local NEON_GLOW: Glow? = GameDefinition.tune(nil :: Glow?, {
	shl3 = table.freeze({ Range = 6, Brightness = 0.5, Shadows = true }),
})
local ARTIFACT_CATEGORY = "artifacts"
local CAPE_CATEGORY = "capes"
local CAPE_ANCHOR_NAME = "UpperTorso"
-- Variables
-- References
-- Private Functions
local function getAnchorFromName(rig: Model, name: string): (BasePart | Attachment)?
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

local function prepItemInst(id: string, item: Instance, isNotRoot: boolean?)
	if item:IsA("BasePart") then
		item.CanCollide = false
		item.CanQuery = false
		item.CanTouch = false
		item.Anchored = false
		-- a live character shouldn't get heavier with every item it wears
		item.Massless = true
	end
	for _, v in item:GetChildren() do
		prepItemInst(id, v, true)
	end
	if not isNotRoot then
		item:AddTag(ITEM_TAG)
		item.Name = id
	end
end

local function newItemInst(item: Item): Result<Instance, string>
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

local function getAnchorName(definitionId: string): Result<string, string>
	local itemTemplateRes = ItemAppearanceDefinition.getTemplate(definitionId)
	if itemTemplateRes.IsErr then
		return Result.err(`item-template error: {itemTemplateRes.Value}`)
	end
	local template = itemTemplateRes.Value
	local root = if template:IsA("Model") then template:FindFirstChild("root") else template
	if not root or not root:IsA("BasePart") then
		return Result.err(`"{definitionId}" isn't worn as a single piece`)
	end
	local attachment = root:FindFirstChildWhichIsA("Attachment", true)
	if not attachment then
		return Result.err(`failed to find valid attachment under part`)
	end
	return Result.ok(attachment.Name)
end

-- a back / neck artifact takes the place of the cape
local function getIfCapeCovered(appearance: Appearance): boolean
	for _, item in appearance.Items do
		local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if itemDefIndexRes.IsErr or itemDefIndexRes.Value.Category ~= ARTIFACT_CATEGORY then
			continue
		end
		local anchorNameRes = getAnchorName(item.DefinitionId)
		if anchorNameRes.IsOk and anchorNameRes.Value == CAPE_ANCHOR_NAME then
			return true
		end
	end
	return false
end

local function getIfHidden(appearance: Appearance, itemDef: ItemDefinition): boolean
	for _, tag in itemDef.Tags do
		if table.find(appearance.HiddenTags, tag :: HiddenTag) then
			return true
		end
	end
	local itemDefIndexRes = ItemAppearanceDefinition.getIndex(itemDef.Id)
	if itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == CAPE_CATEGORY then
		return getIfCapeCovered(appearance)
	end
	return false
end

-- the image is drawn in the color of its group. an item is cloned anew every time it's worn, so a pattern that's
-- taken off again leaves nothing behind
local function applyPattern(part: BasePart, group: TextureGroup)
	local key = group.Pattern
	if not key then
		return
	end
	local patternRes = PatternDefinition.get(key)
	-- a look can be older than the patterns of its game, one that's gone is a part left plain
	if patternRes.IsErr then
		return
	end
	for _, face in PATTERN_FACES do
		local decal = Instance.new("Decal")
		decal.Name = PATTERN_NAME
		decal.Face = face
		decal.Texture = patternRes.Value.Image
		decal.Color3 = group.Color
		decal.Transparency = group.Transparency
		decal.Parent = part
	end
end

local function applyGlow(part: BasePart, group: TextureGroup)
	if not NEON_GLOW or group.Material ~= Enum.Material.Neon then
		return
	end
	local light = Instance.new("PointLight")
	light.Name = GLOW_NAME
	light.Color = group.Color
	light.Range = NEON_GLOW.Range
	light.Brightness = NEON_GLOW.Brightness
	light.Shadows = NEON_GLOW.Shadows
	light.Parent = part
end

local function applyTextureGroups(part: BasePart, appearance: Appearance, item: Item)
	local attr: AppearanceType.TextureGroupKey? = part:GetAttribute("TextureGroup") :: AppearanceType.TextureGroupKey?
	if not attr then
		return
	end
	local group = item.TextureGroups[attr]
	if group then
		part.Color = group.Color
		part.Material = group.Material
		part.Transparency = group.Transparency
		applyPattern(part, group)
		applyGlow(part, group)
	elseif attr == "Skin" then
		-- bare skin the item doesn't color itself matches the body
		part.Color = appearance.SkinColor
	end
end

local function applyBasePart(rig: Model, basePart: BasePart): Result<true, string>
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
		anchorPart = anchorParent
		globalCF = anchorParent.CFrame * anchor.CFrame
	else
		anchorPart = anchor
		globalCF = anchor.CFrame
	end
	globalCF *= attachment.CFrame:Inverse()
	basePart:PivotTo(globalCF)
	WeldUtil.between(anchorPart, basePart)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

local function applyModel(rig: Model, model: Model): Result<true, string>
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
		anchorPart = anchorParent
		globalCF = anchorParent.CFrame * anchor.CFrame
	else
		anchorPart = anchor
		globalCF = anchor.CFrame
	end
	globalCF *= attachment.CFrame:Inverse()
	model.WorldPivot = root.CFrame * root.PivotOffset
	model:PivotTo(globalCF)
	for _, v in model:QueryDescendants("BasePart") do
		if v ~= root then
			WeldUtil.between(root, v)
		end
	end
	WeldUtil.between(anchorPart, root)

	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- Class
local Util = {}

Util.ITEM_TAG = ITEM_TAG

function Util.getAnchorName(definitionId: string): Result<string, string>
	return getAnchorName(definitionId)
end

function Util.apply(rig: Model, appearance: Appearance, item: Item): Result<true, string>
	local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
	if itemDefRes.IsErr then
		return Result.err(`item-def error: {itemDefRes.Value}`)
	end
	-- a face item is drawn onto the head instead, a hidden item stays in the data but isn't worn
	if itemDefRes.Value.Type == "Face" or getIfHidden(appearance, itemDefRes.Value) then
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	local newItemRes = newItemInst(item)
	if newItemRes.IsErr then
		return newItemRes
	end
	local newItem = newItemRes.Value
	if newItem:IsA("BasePart") then
		applyTextureGroups(newItem, appearance, item)
	end
	for _, v in newItem:QueryDescendants("BasePart") do
		applyTextureGroups(v, appearance, item)
	end
	prepItemInst(item.DefinitionId, newItem)
	local applyResOpt: Option<Result<true, string>> = Option.none()
	if newItem:IsA("BasePart") then
		applyResOpt = Option.some(applyBasePart(rig, newItem))
	elseif newItem:IsA("Model") then
		applyResOpt = Option.some(applyModel(rig, newItem))
	elseif newItem:IsA("Folder") then
		applyResOpt = Option.some(Result.ok(true :: any))
		for _, inst in newItem:GetChildren() do
			local applyChildResOpt: Option<Result<true, string>> = Option.none()
			if inst:IsA("BasePart") then
				applyChildResOpt = Option.some(applyBasePart(rig, inst))
			elseif inst:IsA("Model") then
				applyChildResOpt = Option.some(applyModel(rig, inst))
			end
			if applyChildResOpt.IsSome and applyChildResOpt.Value.IsErr then
				applyResOpt = Option.some(Result.err(`piece "{inst.Name}": {applyChildResOpt.Value.Value}`))
				break
			end
		end
	end
	if applyResOpt.IsNone then
		newItem:Destroy()
		return Result.err(`a "{newItem.ClassName}" can't be worn`)
	end
	local applyRes = applyResOpt.Value
	if applyRes.IsErr then
		newItem:Destroy()
	else
		newItem.Parent = rig
	end
	return applyRes
end

-- it's tagged as an item, so the next clear of the rig takes it off again
function Util.applyTemplate(rig: Model, template: Instance): Result<Instance, string>
	local newItem = template:Clone()
	prepItemInst(template.Name, newItem)
	local applyRes: Result<true, string>
	if newItem:IsA("BasePart") then
		applyRes = applyBasePart(rig, newItem)
	elseif newItem:IsA("Model") then
		applyRes = applyModel(rig, newItem)
	else
		applyRes = Result.err(`a "{newItem.ClassName}" can't be worn`)
	end
	if applyRes.IsErr then
		newItem:Destroy()
		return applyRes
	end
	newItem.Parent = rig
	return Result.ok(newItem)
end
return Util
