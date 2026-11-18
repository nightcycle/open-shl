--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Appearance = AppearanceType.Appearance
export type FaceSlot = AppearanceType.FaceSlot
-- Constants
-- drawn bottom to top, the eyebrows go over the eyes which go over the mouth. a game lists its slots the other way
local SLOTS: { FaceSlot } = {}
for _, slot in ItemAppearanceDefinition.listFaceSlots() do
	table.insert(SLOTS, 1, slot)
end
table.freeze(SLOTS)
-- Variables
-- References
-- Private Functions
local function getImage(slot: FaceSlot, definitionId: string): Result<string, string>
	local itemDefRes = ItemAppearanceDefinition.get(definitionId)
	if itemDefRes.IsErr then
		return Result.err(`item-def error: {itemDefRes.Value}`)
	end
	local itemDef = itemDefRes.Value
	if itemDef.Type ~= "Face" or itemDef.Slot ~= slot then
		return Result.err(`"{definitionId}" isn't a face item of the "{slot}" slot`)
	end
	return Result.ok(itemDef.Image)
end
-- Class
local Util = {}

-- the colors only reach the slots the game tints, one that's left out is drawn in the color of its slot
function Util.set(
	rig: Model,
	definitionIds: { [FaceSlot]: string? },
	colors: { [FaceSlot]: Color3? }?
): Result<true, string>
	local fakeHead = rig:FindFirstChild(RigUtil.FAKE_HEAD_NAME)
	if not fakeHead or not fakeHead:IsA("BasePart") then
		return Result.err(`rig "{rig.Name}" has no "{RigUtil.FAKE_HEAD_NAME}" to draw a face on`)
	end
	local errs: { string } = {}
	for zIndex, slot: FaceSlot in SLOTS do
		-- a slot the game has no default for stays bare when nothing is worn in it
		local defaultId = ItemAppearanceDefinition.getDefaultFaceId(slot)
		local definitionId = definitionIds[slot] or defaultId
		local image: string? = nil
		if definitionId then
			local imageRes = getImage(slot, definitionId)
			if imageRes.IsErr then
				table.insert(errs, imageRes.Value)
				if defaultId then
					imageRes = getImage(slot, defaultId)
				end
			end
			image = if imageRes.IsOk then imageRes.Value else nil
		end
		-- each slot keeps a single decal that gets redrawn, so a new face can't leave an old one behind
		local priorDecal = fakeHead:FindFirstChild(slot)
		if image == nil then
			if priorDecal then
				priorDecal:Destroy()
			end
			continue
		end
		local tint = ItemAppearanceDefinition.getFaceTint(slot)
		local color = if tint then (if colors then colors[slot] else nil) or tint else nil
		if priorDecal and priorDecal:IsA("Decal") then
			priorDecal.Texture = image
			if color then
				priorDecal.Color3 = color
			end
			continue
		elseif priorDecal then
			priorDecal:Destroy()
		end
		local decal = Instance.new("Decal")
		decal.Name = slot
		decal.Face = Enum.NormalId.Front
		decal.ZIndex = zIndex
		decal.Texture = image
		if color then
			decal.Color3 = color
		end
		decal.Parent = fakeHead
	end
	if #errs > 0 then
		return Result.err(table.concat(errs, ", "))
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function Util.apply(rig: Model, appearance: Appearance): Result<true, string>
	local definitionIds: { [FaceSlot]: string? } = {}
	local colors: { [FaceSlot]: Color3? } = {}
	for _, item in appearance.Items do
		local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
		if itemDefRes.IsErr then
			continue
		end
		local itemDef = itemDefRes.Value
		if itemDef.Type == "Face" then
			-- an appearance is meant to hold one face item per slot, if it doesn't the newest wins
			definitionIds[itemDef.Slot] = item.DefinitionId
			local group = item.TextureGroups[ItemAppearanceDefinition.FACE_TINT_GROUP_KEY]
			colors[itemDef.Slot] = if group then group.Color else nil
		end
	end
	return Util.set(rig, definitionIds, colors)
end

return Util
