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
local NEUTRAL_KEY = "neutral"
-- drawn bottom to top, the eyebrows go over the eyes which go over the mouth
local SLOTS: { FaceSlot } = table.freeze({ "Mouth" :: FaceSlot, "Eyes", "Eyebrows" })
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

function Util.set(rig: Model, definitionIds: { [FaceSlot]: string? }): Result<true, string>
	local fakeHead = rig:FindFirstChild(RigUtil.FAKE_HEAD_NAME)
	if not fakeHead or not fakeHead:IsA("BasePart") then
		return Result.err(`rig "{rig.Name}" has no "{RigUtil.FAKE_HEAD_NAME}" to draw a face on`)
	end
	local errs: { string } = {}
	for zIndex, slot: FaceSlot in SLOTS do
		local neutralId = ItemAppearanceDefinition.getFaceId(slot, NEUTRAL_KEY)
		local imageRes = getImage(slot, definitionIds[slot] or neutralId)
		if imageRes.IsErr then
			table.insert(errs, imageRes.Value)
			imageRes = getImage(slot, neutralId)
		end
		-- each slot keeps a single decal that gets redrawn, so a new face can't leave an old one behind
		local priorDecal = fakeHead:FindFirstChild(slot)
		if imageRes.IsErr then
			if priorDecal then
				priorDecal:Destroy()
			end
			continue
		end
		if priorDecal and priorDecal:IsA("Decal") then
			priorDecal.Texture = imageRes.Value
			continue
		elseif priorDecal then
			priorDecal:Destroy()
		end
		local decal = Instance.new("Decal")
		decal.Name = slot
		decal.Face = Enum.NormalId.Front
		decal.ZIndex = zIndex
		decal.Texture = imageRes.Value
		decal.Parent = fakeHead
	end
	if #errs > 0 then
		return Result.err(table.concat(errs, ", "))
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function Util.apply(rig: Model, appearance: Appearance): Result<true, string>
	local definitionIds: { [FaceSlot]: string? } = {}
	for _, item in appearance.Items do
		local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
		if itemDefRes.IsErr then
			continue
		end
		local itemDef = itemDefRes.Value
		if itemDef.Type == "Face" then
			-- an appearance is meant to hold one face item per slot, if it doesn't the newest wins
			definitionIds[itemDef.Slot] = item.DefinitionId
		end
	end
	return Util.set(rig, definitionIds)
end

return Util
