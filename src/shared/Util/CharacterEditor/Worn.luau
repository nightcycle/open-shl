--!strict
-- Services
-- Packages
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type ItemGroup = AppearanceType.ItemGroup
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
type WornTextureBinding = CharacterEditorType.WornTextureBinding
-- Constants
-- nil in a game where an item starts out the way it was made
local CHANNEL_DEFAULTS: { [TextureGroupKey]: Color3 }? = CharacterEditorDefinition.CHANNEL_DEFAULTS
-- the one material that goes from what's worn to what's worn next: a group that glows glows all over
local GLOW_MATERIAL = Enum.Material.Neon
-- Variables
-- References
-- Private Functions
local function getIfListed(item: Item, itemGroup: ItemGroup, key: TextureGroupKey): boolean
	local indexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
	if indexRes.IsErr or indexRes.Value.Group ~= itemGroup then
		return false
	end
	local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
	return itemDefRes.IsOk and table.find(itemDefRes.Value.TextureGroups, key) ~= nil
end

-- a group that was never edited looks like the template
local function getTextureGroup(item: Item, key: TextureGroupKey): TextureGroup?
	local group = item.TextureGroups[key]
	if group then
		return group
	end
	local defaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(item.DefinitionId, key)
	return if defaultRes.IsOk then defaultRes.Value else nil
end

local function getIfSame(a: TextureGroup, b: TextureGroup): boolean
	return a.Color == b.Color
		and a.Material == b.Material
		and a.Transparency == b.Transparency
		and a.Pattern == b.Pattern
end

-- the first of what's worn of an item group that lists the texture group, but for the item itself
local function find(appearance: Appearance, itemGroup: ItemGroup, key: TextureGroupKey, definitionId: string?): Item?
	for _, item in appearance.Items do
		if item.DefinitionId ~= definitionId and getIfListed(item, itemGroup, key) then
			return item
		end
	end
	return nil
end
-- Class
-- a game can have a color + a glow picked once for everything an identity wears of an item group: every worn item
-- that lists the texture group takes it, + what goes on afterwards comes in it
local Util = {}

-- what's worn wears the group as: the first of it that lists the group says. nil with nothing worn that does
function Util.get(appearance: Appearance, binding: WornTextureBinding): TextureGroup?
	local item = find(appearance, binding.ItemGroup, binding.Group)
	return if item then getTextureGroup(item, binding.Group) else nil
end

-- every worn item that lists the group takes what's made of its own. the very look comes back when that changes
-- nothing, so a scene doesn't dress its rig again
function Util.set(
	appearance: Appearance,
	binding: WornTextureBinding,
	fn: (group: TextureGroup) -> TextureGroup
): Appearance
	local key: TextureGroupKey = binding.Group
	local groups: { [string]: TextureGroup } = {}
	for _, item in appearance.Items do
		local group = if getIfListed(item, binding.ItemGroup, key) then getTextureGroup(item, key) else nil
		if not group then
			continue
		end
		local editedGroup = fn(group)
		if not getIfSame(editedGroup, group) then
			groups[item.DefinitionId] = editedGroup
		end
	end
	if next(groups) == nil then
		return appearance
	end
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		for _, item in t.Items do
			local group = groups[item.DefinitionId]
			if group then
				item.TextureGroups[key] = group
			end
		end
		return t
	end)
end

-- an item nobody wears yet, the way the look it's about to join has it start out: each of its groups in the color of
-- what's worn of its item group, or in the color the game starts that group out in. a glow comes along, any other
-- material is the item's own. in a game without such colors it's the item the way it was made
function Util.newItem(appearance: Appearance, definitionId: string): Item
	local item = ItemConstructor.new(definitionId)
	local indexRes = ItemAppearanceDefinition.getIndex(definitionId)
	local itemDefRes = ItemAppearanceDefinition.get(definitionId)
	if not CHANNEL_DEFAULTS or indexRes.IsErr or itemDefRes.IsErr then
		return item
	end
	local groups: { [TextureGroupKey]: TextureGroup } = {}
	for _, key: TextureGroupKey in itemDefRes.Value.TextureGroups do
		local color: Color3? = CHANNEL_DEFAULTS[key]
		local defaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(definitionId, key)
		if not color or defaultRes.IsErr then
			continue
		end
		local default = defaultRes.Value
		local material = default.Material
		local wornItem = find(appearance, indexRes.Value.Group, key, definitionId)
		local wornGroup = if wornItem then getTextureGroup(wornItem, key) else nil
		if wornGroup then
			color = wornGroup.Color
			material = if wornGroup.Material == GLOW_MATERIAL then GLOW_MATERIAL else material
		end
		local group = TextureGroupConstructor.new(color, material, default.Transparency)
		-- a group that comes out the way the item was made isn't stored
		if not getIfSame(group, default) then
			groups[key] = group
		end
	end
	if next(groups) == nil then
		return item
	end
	return FreezeUtil.delta(item, function(t: Item): Item
		for key: TextureGroupKey, group in groups do
			t.TextureGroups[key] = group
		end
		return t
	end)
end

return Util
