--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
local BodyUtil = require("@self/Body")
local FaceUtil = require("@self/Face")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemUtil = require("@self/Item")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type HiddenTag = AppearanceType.HiddenTag
-- Constants
local ARTIFACT_CATEGORY = "artifacts"
local GLASSES_CATEGORY = "glasses"
local HEAD_ANCHOR_NAME = "Head"
local HAIR_TAG: HiddenTag = "Hair"
local UNMASKED_HIDDEN_TAGS: { HiddenTag } = table.freeze({ "Mask" :: HiddenTag, "Hood", "MouthCover" })
-- Variables
local RequestCounts: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
-- References
-- Private Functions
-- the newest request on a rig wins, an older one stops as soon as it notices
local function newGetIfStopped(rig: Model, getIfCanceled: () -> boolean): () -> boolean
	local requestCount = (RequestCounts[rig] or 0) + 1
	RequestCounts[rig] = requestCount
	return function(): boolean
		return getIfCanceled() or RequestCounts[rig] ~= requestCount
	end
end

local function getIfTagged(item: Item, tag: HiddenTag): boolean
	local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
	return itemDefRes.IsOk and table.find(itemDefRes.Value.Tags, tag) ~= nil
end

local function getIfCategory(item: Item, category: string): boolean
	local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
	return itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == category
end

local function getIfHairShows(appearance: Appearance): boolean
	if table.find(appearance.HiddenTags, HAIR_TAG) then
		return false
	end
	for _, item in appearance.Items do
		if getIfTagged(item, HAIR_TAG) then
			return true
		end
	end
	return false
end

-- the body is built for the look that goes onto it, without one it's the body the game starts a look on
local function clear(rig: Model, skinColor: Color3?, appearance: Appearance?, getIfCanceled: () -> boolean): boolean
	local builder = BodyUtil.describe(HumanoidDescriptionBuilder.new(), appearance)
	if skinColor then
		builder = builder:addBodyColor(skinColor)
	end
	local desc = builder:build()
	local f = Future.awaitUntil(RigUtil.applyDescription(rig, desc), getIfCanceled)
	if f.IsCanceled then
		-- the request may still be reading the description, it's collected once nothing holds it
		return false
	end
	desc:Destroy()
	-- a newer request can start + finish in the frame it takes to notice the description is done
	if getIfCanceled() then
		return false
	end
	for _, v in rig:QueryDescendants(`.{ItemUtil.ITEM_TAG}`) do
		v:Destroy()
	end
	return true
end

local function apply(rig: Model, appearance: Appearance, getIfCanceled: () -> boolean): Result<true, { string }>?
	if not rig:FindFirstChildWhichIsA("Humanoid") then
		return Result.err({ `rig "{rig.Name}" has no humanoid` })
	end
	if not clear(rig, appearance.SkinColor, appearance, getIfCanceled) then
		return nil
	end
	local errs = {}
	local function wear(item: Item)
		-- one broken item shouldn't cost the rig the rest of the outfit
		local success, res = pcall(ItemUtil.apply, rig, appearance, item)
		if not success then
			table.insert(errs, `item "{item.DefinitionId}" threw: {res}`)
		elseif res.IsErr then
			table.insert(errs, `item "{item.DefinitionId}" failed to apply: {res.Value}`)
		end
	end
	-- what sits on a worn piece goes on once everything that sits on the body is
	local hungItems: { Item } = {}
	for _, item in appearance.Items do
		if ItemUtil.getIfHung(rig, item.DefinitionId) then
			table.insert(hungItems, item)
		else
			wear(item)
		end
	end
	for _, item in hungItems do
		wear(item)
	end
	local faceRes = FaceUtil.apply(rig, appearance)
	if faceRes.IsErr then
		table.insert(errs, `face failed to apply: {faceRes.Value}`)
	end
	if #errs > 0 then
		return Result.err(errs)
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end
-- Class
local Util = {}

function Util.clear(rig: Model, skinColor: Color3?): TypeUnionLib.ToDo<true>
	return Future.toDo(function(getIfCanceled): true?
		local success, isCleared = pcall(clear, rig, skinColor, nil, newGetIfStopped(rig, getIfCanceled))
		if not success then
			warn(`rig "{rig.Name}" failed to clear: {isCleared}`)
			return nil
		end
		return if isCleared then true else nil
	end)
end

function Util.apply(rig: Model, appearance: Appearance): TypeUnionLib.ToDo<Result<true, { string }>>
	return Future.toDo(function(getIfCanceled): Result<true, { string }>?
		-- a throw inside of a future leaves it incomplete forever, so it has to come back as an error
		local success, res = pcall(apply, rig, appearance, newGetIfStopped(rig, getIfCanceled))
		if not success then
			return Result.err({ `appearance threw: {res}` })
		end
		return res
	end)
end

-- only the face, a change of expression isn't worth a whole new apply
function Util.applyFace(rig: Model, appearance: Appearance): Result<true, string>
	return FaceUtil.apply(rig, appearance)
end

-- the look of a hero with the mask off: it's only ever worn, never saved
function Util.unmask(appearance: Appearance, secretAppearance: Appearance?): Appearance
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		for _, tag in UNMASKED_HIDDEN_TAGS do
			if not table.find(t.HiddenTags, tag) then
				table.insert(t.HiddenTags, tag)
			end
		end
		-- an artifact worn on the head comes off with the mask
		for i = #t.Items, 1, -1 do
			local item = t.Items[i]
			if getIfCategory(item, ARTIFACT_CATEGORY) then
				local anchorNameRes = ItemUtil.getAnchorName(item.DefinitionId)
				if anchorNameRes.IsOk and anchorNameRes.Value == HEAD_ANCHOR_NAME then
					table.remove(t.Items, i)
				end
			end
		end
		if secretAppearance and not getIfHairShows(t) then
			-- with nothing left on the head the civilian hair + glasses show
			for i = #t.Items, 1, -1 do
				if getIfTagged(t.Items[i], HAIR_TAG) then
					table.remove(t.Items, i)
				end
			end
			local hairIndex = table.find(t.HiddenTags, HAIR_TAG)
			if hairIndex then
				table.remove(t.HiddenTags, hairIndex)
			end
			for _, item in secretAppearance.Items do
				if getIfTagged(item, HAIR_TAG) or getIfCategory(item, GLASSES_CATEGORY) then
					table.insert(t.Items, item)
				end
			end
		end
		return t
	end)
end

return Util
