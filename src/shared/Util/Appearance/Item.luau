--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
-- Modules
local BodyUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Body")
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
type Anchor = {
	Part: BasePart, -- what the piece is welded to
	CFrame: CFrame, -- where the attachment of the piece goes
	Limb: BasePart, -- the part of the body all of it moves with
}
-- Constants
local ITEM_TAG = "AppearanceItem"
local ROOT_NAME = "root"
local WELD_NAME = "Weld"
-- a suit's torso is where an emblem + a cape go
local TORSO_NAMES: { string } = table.freeze({ "UpperTorso", "LowerTorso" })
-- further than any piece is welded away from the body
local MAX_WELD_COUNT = 8
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
local FACIAL_HAIR_CATEGORY = "facial-hair"
local HAIR_TAG: HiddenTag = "Hair"
-- what a helmet says of the hair + the beard there's no room for under it
local SHAVE_HEAD_ATTRIBUTE = "ShaveHead"
local SHAVE_BEARD_ATTRIBUTE = "ShaveBeard"
-- Variables
-- References
-- Private Functions
local function getBodyPart(rig: Model, name: string): BasePart?
	return IndexUtil.findFirstMatch(rig, function(v: Instance): BasePart?
		if v:IsA("BasePart") and v.Name == name then
			return v
		end
		return nil
	end)
end

-- the part of the body a worn part hangs off, through whatever it's welded to
local function getLimb(rig: Model, part: BasePart): BasePart?
	local current = part
	for _ = 1, MAX_WELD_COUNT do
		if current.Parent == rig and not current:HasTag(ITEM_TAG) then
			return current
		end
		local weld = current:FindFirstChild(WELD_NAME)
		local part0 = if weld and weld:IsA("Weld") then weld.Part0 else nil
		if not part0 then
			return nil
		end
		current = part0
	end
	return nil
end

-- what isn't named after a part of the body sits on a piece that's worn already, on the attachment of that name the
-- piece brings along. one on the torso wins over any other
local function getMountAnchor(rig: Model, name: string): Anchor?
	local anchor: Anchor? = nil
	for _, item in rig:GetChildren() do
		if not item:HasTag(ITEM_TAG) then
			continue
		end
		for _, attachment: Attachment in item:QueryDescendants("Attachment") :: { Attachment } do
			local part = attachment.Parent
			-- the attachment of a root, or of an item that's a single part, is the one that piece is worn by itself
			if
				attachment.Name ~= name
				or not part
				or not part:IsA("BasePart")
				or part == item
				or part.Name == ROOT_NAME
			then
				continue
			end
			local limb = getLimb(rig, part)
			if not limb then
				continue
			end
			local isTorso = table.find(TORSO_NAMES, limb.Name) ~= nil
			if isTorso or not anchor then
				anchor = { Part = part, CFrame = part.CFrame * attachment.CFrame, Limb = limb }
			end
			if isTorso then
				return anchor
			end
		end
	end
	return anchor
end

local function getAnchor(rig: Model, name: string): Anchor?
	local bodyPart = getBodyPart(rig, name)
	if bodyPart then
		return { Part = bodyPart, CFrame = bodyPart.CFrame, Limb = bodyPart }
	end
	return getMountAnchor(rig, name)
end

-- a frame once the space it's in is stretched along the axes of that space
local function stretch(cf: CFrame, scale: Vector3): CFrame
	return cf.Rotation + cf.Position * scale
end

-- how much longer each of its own axes gets by that
local function getGrowth(cf: CFrame, scale: Vector3): Vector3
	return Vector3.new((cf.XVector * scale).Magnitude, (cf.YVector * scale).Magnitude, (cf.ZVector * scale).Magnitude)
end

-- a piece is made for the body as it comes. on a body of another size all of it grows + moves out from where it's
-- worn by as much as that part of the body did
local function fit(root: BasePart, attachment: Attachment, parts: { BasePart }, anchor: Anchor, limbScale: Vector3)
	-- the body is sized along the axes of its parts, what sits on a worn attachment can be turned against those
	local scale = getGrowth(anchor.Limb.CFrame:ToObjectSpace(anchor.CFrame), limbScale)
	-- where the root is once the attachment is on its anchor
	local rootCF = attachment.CFrame:Inverse()
	local newRootCF = stretch(rootCF, scale)
	local rootWorldCF = root.CFrame
	for _, part in parts do
		local cf = rootCF * rootWorldCF:ToObjectSpace(part.CFrame)
		local growth = getGrowth(cf, scale)
		part.Size *= growth
		for _, v in part:GetChildren() do
			if v:IsA("DataModelMesh") then
				-- only a mesh out of a file has a size of its own, the others fill their part
				if v:IsA("SpecialMesh") and v.MeshType == Enum.MeshType.FileMesh then
					v.Scale *= growth
				end
				v.Offset *= growth
			elseif v:IsA("Attachment") and v ~= attachment then
				-- whatever is worn on the piece moves out with it
				v.CFrame = stretch(v.CFrame, growth)
			end
		end
		if part ~= root then
			part.CFrame = rootWorldCF * newRootCF:Inverse() * stretch(cf, scale)
		end
	end
	attachment.CFrame = newRootCF:Inverse()
end

-- an item that stands for the parts of the body it's worn on leaves none of them to be seen. each of its pieces is
-- worn by its root, a piece that's a single part by itself
local function hideBody(rig: Model, item: Instance)
	local parts = item:QueryDescendants("BasePart") :: { BasePart }
	if item:IsA("BasePart") then
		table.insert(parts, item)
	end
	for _, part in parts do
		if part ~= item and part.Name ~= ROOT_NAME then
			continue
		end
		local limb = getLimb(rig, part)
		if limb then
			BodyUtil.hide(limb)
		end
	end
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
	local root = if template:IsA("Model") then template:FindFirstChild(ROOT_NAME) else template
	if not root or not root:IsA("BasePart") then
		return Result.err(`"{definitionId}" isn't worn as a single piece`)
	end
	local attachment = root:FindFirstChildWhichIsA("Attachment", true)
	if not attachment then
		return Result.err(`failed to find valid attachment under part`)
	end
	return Result.ok(attachment.Name)
end

-- what a single piece sits on when that's no part of the body: a piece that's worn has to bring it along
local function getMountName(rig: Model, definitionId: string): string?
	local anchorNameRes = getAnchorName(definitionId)
	if anchorNameRes.IsErr or getBodyPart(rig, anchorNameRes.Value) then
		return nil
	end
	return anchorNameRes.Value
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

local function getIfTagHidden(appearance: Appearance, itemDef: ItemDefinition): boolean
	for _, tag in itemDef.Tags do
		if table.find(appearance.HiddenTags, tag :: HiddenTag) then
			return true
		end
	end
	return false
end

-- a piece that leaves no room for what grows under it says so on its template. one that's hidden itself hides nothing
local function getIfShaved(appearance: Appearance, attribute: string): boolean
	for _, item in appearance.Items do
		local templateRes = ItemAppearanceDefinition.getTemplate(item.DefinitionId)
		if templateRes.IsErr or templateRes.Value:GetAttribute(attribute) ~= true then
			continue
		end
		local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
		if itemDefRes.IsOk and not getIfTagHidden(appearance, itemDefRes.Value) then
			return true
		end
	end
	return false
end

local function getIfHidden(appearance: Appearance, itemDef: ItemDefinition): boolean
	if getIfTagHidden(appearance, itemDef) then
		return true
	end
	local itemDefIndexRes = ItemAppearanceDefinition.getIndex(itemDef.Id)
	if itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == CAPE_CATEGORY then
		return getIfCapeCovered(appearance)
	end
	if table.find(itemDef.Tags, HAIR_TAG) then
		return getIfShaved(appearance, SHAVE_HEAD_ATTRIBUTE)
	end
	if itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == FACIAL_HAIR_CATEGORY then
		return getIfShaved(appearance, SHAVE_BEARD_ATTRIBUTE)
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

local function applyBasePart(rig: Model, basePart: BasePart, appearance: Appearance?): Result<true, string>
	local attachments = basePart:QueryDescendants("Attachment") :: { Attachment }
	if #attachments == 0 then
		return Result.err(`failed to find valid attachment under part`)
	elseif #attachments > 1 then
		return Result.err(`returned #{attachments} attachments, expected only one`)
	end
	local attachment = attachments[1]
	local anchor = getAnchor(rig, attachment.Name)
	if not anchor then
		return Result.err(`attachment name "{attachment.Name}" couldn't be mapped into a valid anchor instance`)
	end
	local scale = if appearance then BodyUtil.getFit(appearance, anchor.Limb.Name) else nil
	if scale then
		fit(basePart, attachment, { basePart }, anchor, scale)
	end
	basePart:PivotTo(anchor.CFrame * attachment.CFrame:Inverse())
	WeldUtil.between(anchor.Part, basePart)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

local function applyModel(rig: Model, model: Model, appearance: Appearance?): Result<true, string>
	local root = model:FindFirstChild(ROOT_NAME)
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
	local anchor = getAnchor(rig, attachment.Name)
	if not anchor then
		return Result.err(`attachment name "{attachment.Name}" couldn't be mapped into a valid anchor instance`)
	end
	local scale = if appearance then BodyUtil.getFit(appearance, anchor.Limb.Name) else nil
	if scale then
		fit(root, attachment, model:QueryDescendants("BasePart") :: { BasePart }, anchor, scale)
	end
	model.WorldPivot = root.CFrame * root.PivotOffset
	model:PivotTo(anchor.CFrame * attachment.CFrame:Inverse())
	for _, v in model:QueryDescendants("BasePart") do
		if v ~= root then
			WeldUtil.between(root, v)
		end
	end
	WeldUtil.between(anchor.Part, root)

	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- Class
local Util = {}

Util.ITEM_TAG = ITEM_TAG

function Util.getAnchorName(definitionId: string): Result<string, string>
	return getAnchorName(definitionId)
end

-- an item that sits on a worn piece instead of on the body can only go on after the item that piece is of
function Util.getIfHung(rig: Model, definitionId: string): boolean
	return getMountName(rig, definitionId) ~= nil
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
	-- so does an emblem or a cape with nothing under it to sit on
	local mountName = getMountName(rig, item.DefinitionId)
	if mountName and not getMountAnchor(rig, mountName) then
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
		applyResOpt = Option.some(applyBasePart(rig, newItem, appearance))
	elseif newItem:IsA("Model") then
		applyResOpt = Option.some(applyModel(rig, newItem, appearance))
	elseif newItem:IsA("Folder") then
		applyResOpt = Option.some(Result.ok(true :: any))
		for _, inst in newItem:GetChildren() do
			local applyChildResOpt: Option<Result<true, string>> = Option.none()
			if inst:IsA("BasePart") then
				applyChildResOpt = Option.some(applyBasePart(rig, inst, appearance))
			elseif inst:IsA("Model") then
				applyChildResOpt = Option.some(applyModel(rig, inst, appearance))
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
		if itemDefRes.Value.Type == "Model" and itemDefRes.Value.IsBodyHidden then
			hideBody(rig, newItem)
		end
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
