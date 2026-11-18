--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
-- Types
type Option<V> = TypeUnionLib.Option<V>
type PageBuilder = PageBuilder.Builder
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
type Tag = CharacterEditorType.Tag
type WearRule = CharacterEditorType.WearRule
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type ItemDefinition = AppearanceType.ItemDefinition
type TextureGroupKey = AppearanceType.TextureGroupKey
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
-- Constants
-- the page every game's tree hangs from, a path is read from it down
local ROOT_KEY = "ROOT"
-- the group the palettes of an item page edit, the first of these that the item has
local MAIN_TEXTURE_GROUP_KEYS: { TextureGroupKey } = table.freeze({ "Primary" :: TextureGroupKey, "Hair" })
-- the edges of an emblem + the lenses of a mask
local DETAIL_TEXTURE_GROUP_KEY: TextureGroupKey = "Secondary"
-- Variables
-- References
-- Private Functions
local function getPowerGroupChoices(group: PowerType.PowerGroup): { ChoiceDefinition }
	local out = {}
	for _, powerDef in PowerDefinition.list(group) do
		table.insert(out, ChoiceDefinitionConstructor.textIcon(powerDef.Id, powerDef.Name, powerDef.Icon))
	end
	return out
end
-- the value of a style choice is the style itself, the same thing an appearance saves
local function getDeathStyleChoices(): { ChoiceDefinition }
	local out = {}
	for _, deathDef in TransitionDefinition.listDeaths() do
		table.insert(out, ChoiceDefinitionConstructor.text(deathDef.Style, deathDef.Name))
	end
	return out
end
local function getTransformationStyleChoices(): { ChoiceDefinition }
	local out = {}
	for _, transformationDef in TransitionDefinition.listTransformations() do
		table.insert(out, ChoiceDefinitionConstructor.text(transformationDef.Style, transformationDef.Name))
	end
	return out
end
local function getMainTextureGroup(itemDef: ItemDefinition): Option<TextureGroupKey>
	for _, key: TextureGroupKey in MAIN_TEXTURE_GROUP_KEYS do
		if table.find(itemDef.TextureGroups, key) then
			return Option.some(key :: any) :: TypeUnionLib.Some<TextureGroupKey>
		end
	end
	return Option.none()
end
local function newItemPage(
	key: string,
	group: AppearanceType.ItemGroup,
	category: string,
	wearRule: WearRule,
	fn: (ItemDefinition, WearRule) -> PageBuilder
): PageBuilder
	local builder = PageBuilder.new(key)
	for _, app in AppearanceItemDefinition.list(group, category) do
		builder = builder:addChild(fn(app, wearRule):build())
	end
	return builder
end
local function newAccessoryPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	local builder = PageBuilder.newItem(itemDef.Id, wearRule)
		:insertToggleField("IsItemAdded", "Add Item", "Filled", "Remove Item")
	-- a palette would do nothing to an item with nothing to recolor
	if getMainTextureGroup(itemDef).IsNone then
		return builder
	end
	return builder:insertColorField({ Type = "ItemTexture" }):insertMaterialField({ Type = "ItemTexture" })
end
local function newEmblemPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	local builder = newAccessoryPageBuilder(itemDef, wearRule)
	if table.find(itemDef.TextureGroups, DETAIL_TEXTURE_GROUP_KEY) == nil then
		return builder
	end
	return builder:insertToggleField("IsEdgeFocused", "Edit Edges", "Outline")
end
local function newMaskPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	local builder = newAccessoryPageBuilder(itemDef, wearRule)
	-- only the masks that were made with lenses can show them
	if table.find(itemDef.TextureGroups, DETAIL_TEXTURE_GROUP_KEY) == nil then
		return builder
	end
	return builder
		:insertToggleField("HasLenses", "Add Lenses", "Filled", "Remove Lenses")
		:insertToggleField("IsLensFocused", "Edit Lenses", "Outline", nil, nil, nil, { "HasNoLenses" :: Tag })
end
-- Class
-- what a game's page tree is put together from. it's beside the trees, a tree can't ask the module above it for
-- anything while that one is busy requiring the tree
local Module = {}

Module.ROOT_KEY = ROOT_KEY
Module.DETAIL_TEXTURE_GROUP_KEY = DETAIL_TEXTURE_GROUP_KEY

Module.getMainTextureGroup = getMainTextureGroup

Module.getPowerGroupChoices = getPowerGroupChoices
Module.getDeathStyleChoices = getDeathStyleChoices
Module.getTransformationStyleChoices = getTransformationStyleChoices

Module.newItemPage = newItemPage
Module.newAccessoryPageBuilder = newAccessoryPageBuilder
Module.newEmblemPageBuilder = newEmblemPageBuilder
Module.newMaskPageBuilder = newMaskPageBuilder

return Module
