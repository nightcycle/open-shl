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
type PageDefinition = CharacterEditorType.PageDefinition
type Tag = CharacterEditorType.Tag
type WearRule = CharacterEditorType.WearRule
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type ItemDefinition = AppearanceType.ItemDefinition
type TextureGroupKey = AppearanceType.TextureGroupKey
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
-- Constants
local ROOT_KEY = "ROOT"
local PATH_DELIMITER = "/"
-- the server cuts a saved name + backstory down to the same lengths
local MAX_NAME_LENGTH = 30
local MAX_BACKSTORY_LENGTH = 150
-- the group the palettes of an item page edit, the first of these that the item has
local MAIN_TEXTURE_GROUP_KEYS: { TextureGroupKey } = table.freeze({ "Primary" :: TextureGroupKey, "Hair" })
-- the edges of an emblem + the lenses of a mask
local DETAIL_TEXTURE_GROUP_KEY: TextureGroupKey = "Secondary"
-- Variables
local ItemPaths: { [string]: string } = {}
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
local function getPathSegments(path: string): { string }
	local segments = path:split(PATH_DELIMITER)
	if segments[1] == "" then
		table.remove(segments, 1)
	end
	if segments[1] == ROOT_KEY then
		table.remove(segments, 1)
	end
	if segments[#segments] == "" then
		table.remove(segments)
	end
	return segments
end
local function getParentPath(path: string): Option<string>
	local segments = getPathSegments(path)
	if #segments == 0 then
		return Option.none()
	end
	table.remove(segments)
	return Option.some(table.concat(segments, PATH_DELIMITER))
end

-- Class
local Module = {}

Module.MAX_NAME_LENGTH = MAX_NAME_LENGTH
Module.MAX_BACKSTORY_LENGTH = MAX_BACKSTORY_LENGTH
Module.DETAIL_TEXTURE_GROUP_KEY = DETAIL_TEXTURE_GROUP_KEY

Module.DEFINITION = PageBuilder.new(ROOT_KEY)
	:addChild(PageBuilder.new("Basic Information")
		:addChild(
			PageBuilder.new("Name")
				:insertTextField({ Type = "Profile", Key = "Name" }, "Insert Name Here", MAX_NAME_LENGTH)
				:insertGenerateAliasField({ Type = "Profile", Key = "Name" }, { "IsSecret" :: Tag })
				:build()
		)
		:addChild(
			PageBuilder.new("Backstory")
				:insertTextField(
					{ Type = "Profile", Key = "Backstory" },
					"Insert Story Here",
					MAX_BACKSTORY_LENGTH,
					true
				)
				:build()
		)
		:addChild(PageBuilder.new("Alignment")
			:insertChooseField({ Type = "Alignment", Axis = "Morality" }, {
				ChoiceDefinitionConstructor.text("Evil"),
				ChoiceDefinitionConstructor.text("Neutral"),
				ChoiceDefinitionConstructor.text("Good"),
			}, "Choose One:")
			:insertChooseField({ Type = "Alignment", Axis = "Order" }, {
				ChoiceDefinitionConstructor.text("Chaotic"),
				ChoiceDefinitionConstructor.text("Neutral"),
				ChoiceDefinitionConstructor.text("Lawful"),
			}, "Choose One:")
			:build())
		:addChild(
			PageBuilder.new("Powers")
				:insertSectionHeaderField("Choose Four Powers", { Type = "PowerLimit" })
				:insertChoiceListField(
					{ Type = "Powers", Group = "basic-melee" },
					getPowerGroupChoices("basic-melee"),
					"-Basic Melee-"
				)
				:insertChoiceListField(
					{ Type = "Powers", Group = "advanced-melee" },
					getPowerGroupChoices("advanced-melee"),
					"-Advanced Melee-"
				)
				:insertChoiceListField(
					{ Type = "Powers", Group = "ranged" },
					getPowerGroupChoices("ranged"),
					"-Ranged-"
				)
				:insertChoiceListField(
					{ Type = "Powers", Group = "transportation" },
					getPowerGroupChoices("transportation"),
					"-Transportation-"
				)
				:insertChoiceListField(
					{ Type = "Powers", Group = "special" },
					getPowerGroupChoices("special"),
					"-Special-"
				)
				:build()
		)
		:addChild(PageBuilder.new("Skin Color"):insertColorField({ Type = "SkinColor" }):build())
		:addChild(
			PageBuilder.new("Death Style")
				:insertChooseField(
					{ Type = "Transition", TransitionType = "Death" },
					getDeathStyleChoices(),
					"Choose a Death Style",
					true
				)
				:build()
		)
		:addChild(
			PageBuilder.new("Transformation Style")
				:insertChooseField(
					{ Type = "Transition", TransitionType = "Transformation" },
					getTransformationStyleChoices(),
					"Choose a Transformation Style",
					true
				)
				:build()
		)
		:build())
	:addChild(
		newItemPage("Arm Armor", "costume", "arm-armor", "Multi", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Chest Armor", "costume", "chest-armor", "Multi", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Emblems", "costume", "emblems", "Single", newEmblemPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Mouth Covers", "costume", "mouth-covers", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Masks", "costume", "masks", "Single", newMaskPageBuilder):insertExclusionTag("IsSecret"):build()
	)
	:addChild(
		newItemPage("Hoods", "costume", "hoods", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Shorts", "costume", "shorts", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Boots", "costume", "boots", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Capes", "costume", "capes", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Suit", "costume", "suit", "Single", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build()
	)
	:addChild(
		newItemPage("Leg Armor", "costume", "leg-armor", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Glasses", "clothing", "glasses", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Gloves", "clothing", "gloves", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Hats", "clothing", "hats", "Single", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build()
	)
	:addChild(
		newItemPage("Jackets", "clothing", "jackets", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Pants", "clothing", "pants", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Shirts", "clothing", "shirts", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Shoes", "clothing", "shoes", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Socks", "clothing", "socks", "Single", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(
		newItemPage("Accessories", "clothing", "accessories", "Multi", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(newItemPage("Eyebrows", "cosmetics", "eyebrows", "Single", newAccessoryPageBuilder):build())
	:addChild(newItemPage("Eyes", "cosmetics", "eyes", "Single", newAccessoryPageBuilder):build())
	:addChild(newItemPage("Facial Hair", "cosmetics", "facial-hair", "Single", newAccessoryPageBuilder):build())
	:addChild(newItemPage("Mouths", "cosmetics", "mouth", "Single", newAccessoryPageBuilder):build())
	:addChild(newItemPage("Hair", "cosmetics", "hair", "MultiHair", newAccessoryPageBuilder):build())
	:build()

function Module.getPage(path: string): Option<PageDefinition>
	local segments = getPathSegments(path)
	table.insert(segments, 1, ROOT_KEY)
	local function getPage(pageDef: PageDefinition, index: number): Option<PageDefinition>
		local segment = segments[index]
		local key = if pageDef.Type == "Default" then pageDef.Key else pageDef.DefinitionId
		if key ~= segment then
			return Option.none()
		end
		if index == #segments then
			return Option.some(pageDef)
		end
		if pageDef.Type == "Default" and pageDef.Children then
			for _, child in pageDef.Children do
				local childOpt = getPage(child, index + 1)
				if childOpt.IsSome then
					return childOpt
				end
			end
		end
		return Option.none()
	end

	return getPage(Module.DEFINITION, 1)
end

Module.getParentPath = getParentPath

function Module.getParentPage(path: string): Option<PageDefinition>
	return Option.flatten(Option.map(getParentPath(path), function(parentPath: string): Option<PageDefinition>
		return Module.getPage(parentPath)
	end))
end

function Module.getChildPath(path: string, pageDef: PageDefinition): string
	local segments = getPathSegments(path)
	table.insert(segments, if pageDef.Type == "Item" then pageDef.DefinitionId else pageDef.Key)
	return table.concat(segments, PATH_DELIMITER)
end
function Module.findFirstFolderPath(path: string): string
	do
		local page = Module.getPage(path)
		if page.IsSome and page.Value.Type == "Default" and page.Value.Children then
			return path
		end
	end
	local parentPathOpt = getParentPath(path)
	while parentPathOpt.IsSome do
		local parentPage = Module.getPage(parentPathOpt.Value)
		if parentPage.IsSome then
			if parentPage.Value.Type == "Default" and parentPage.Value.Children then
				return parentPathOpt.Value
			else
				parentPathOpt = getParentPath(parentPathOpt.Value)
			end
		else
			return ""
		end
	end
	return ""
end
function Module.findFirstFolderPage(path: string): Option<PageDefinition>
	return Module.getPage(Module.findFirstFolderPath(path))
end

-- the same page can be spelled with or without the root + slashes around it, this is the spelling paths are compared in
function Module.fixPath(path: string): string
	return table.concat(getPathSegments(path), PATH_DELIMITER)
end

-- none for an item the editor doesn't offer (an artifact)
function Module.getItemPath(definitionId: string): Option<string>
	return Option.from(ItemPaths[definitionId])
end

Module.getMainTextureGroup = getMainTextureGroup

do
	local function indexItemPaths(pageDef: PageDefinition, path: string)
		if pageDef.Type == "Item" then
			ItemPaths[pageDef.DefinitionId] = path
		elseif pageDef.Children then
			for _, child in pageDef.Children do
				indexItemPaths(child, Module.getChildPath(path, child))
			end
		end
	end
	indexItemPaths(Module.DEFINITION, "")
end

return Module
