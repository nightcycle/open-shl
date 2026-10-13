--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
-- Types
type Option<V> = TypeUnionLib.Option<V>
type PageBuilder = PageBuilder.Builder
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
type PageDefinition = CharacterEditorType.PageDefinition
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
-- Constants
local ROOT_KEY = "ROOT"
-- Variables
-- References
-- Private Functions
function getPowerGroupChoices(
	group: "basic-melee" | "advanced-melee" | "ranged" | "transportation" | "special"
): { ChoiceDefinition }
	return {}
end
function newItemPage(
	key: string,
	group: AppearanceType.ItemGroup,
	category: string,
	fn: (AppearanceType.ItemDefinition) -> PageBuilder
): PageBuilder
	local builder = PageBuilder.new(key)
	for i, app in AppearanceItemDefinition.list(group, category) do
		builder = builder:addChild(fn(app):build())
	end
	return builder
end
function newAccessoryPageBuilder(itemDef: AppearanceType.ItemDefinition): PageBuilder
	return PageBuilder.newItem(itemDef.Id)
		:insertToggleField("IsItemAdded", "Add Item", "Filled", "Remove Item")
		:insertColorField()
		:insertMaterialField()
end
local function getPathSegments(path: string): { string }
	local segments = path:split("/")
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
	return Option.some(table.concat(segments, "/"))
end

-- Class
local Module = {}

Module.DEFINITION = PageBuilder.new(ROOT_KEY)
	:addChild(PageBuilder.new("Basic Information")
		:addChild(PageBuilder.new("Name"):insertTextField(nil, 30):insertGenerateAliasField():build())
		:addChild(PageBuilder.new("Backstory"):insertTextField(nil, 120, true):build())
		:addChild(PageBuilder.new("Alignment")
			:insertChooseField({
				ChoiceDefinitionConstructor.text("Evil"),
				ChoiceDefinitionConstructor.text("Neutral"),
				ChoiceDefinitionConstructor.text("Good"),
			}, "Choose One:")
			:insertChooseField({
				ChoiceDefinitionConstructor.text("Chaotic"),
				ChoiceDefinitionConstructor.text("Neutral"),
				ChoiceDefinitionConstructor.text("Lawful"),
			}, "Choose One:")
			:build())
		:addChild(
			PageBuilder.new("Powers")
				:insertSectionHeaderField("Choose Five Powers")
				:insertChoiceListField(getPowerGroupChoices("basic-melee"), "-Basic Melee-")
				:insertChoiceListField(getPowerGroupChoices("advanced-melee"), "-Advanced Melee-")
				:insertChoiceListField(getPowerGroupChoices("ranged"), "-Ranged-")
				:insertChoiceListField(getPowerGroupChoices("transportation"), "-Transportation-")
				:insertChoiceListField(getPowerGroupChoices("special"), "-Special-")
				:build()
		)
		:addChild(PageBuilder.new("Skin Color"):insertColorField():build())
		:addChild(PageBuilder.new("Death Style")
			:insertChooseField({
				ChoiceDefinitionConstructor.text("Fall Backwards"),
				ChoiceDefinitionConstructor.text("Fall Forwards"),
			}, "Choose a Death Style")
			:build())
		:addChild(PageBuilder.new("Transformation Style")
			:insertChooseField({
				ChoiceDefinitionConstructor.text("Ascension"),
				ChoiceDefinitionConstructor.text("Spin"),
				ChoiceDefinitionConstructor.text("Fire"),
				ChoiceDefinitionConstructor.text("Smoke"),
			}, "Choose a Transformation Style")
			:build())
		:build())
	:addChild(
		newItemPage("Arm Armor", "costume", "arm-armor", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build()
	)
	:addChild(
		newItemPage("Chest Armor", "costume", "chest-armor", newAccessoryPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Emblems", "costume", "emblems", function(itemDef: AppearanceItemDefinition.ItemDefinition): PageBuilder
				return newAccessoryPageBuilder(itemDef):insertToggleField("IsEdgeFocused", "Edit Edges", "Outline")
			end)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage(
				"Mouth Covers",
				"costume",
				"mouth-covers",
				function(itemDef: AppearanceItemDefinition.ItemDefinition): PageBuilder
					return newAccessoryPageBuilder(itemDef):insertToggleField("IsEdgeFocused", "Edit Edges", "Outline")
				end
			)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		newItemPage("Masks", "costume", "masks", function(itemDef: AppearanceItemDefinition.ItemDefinition): PageBuilder
				return newAccessoryPageBuilder(itemDef)
					:insertToggleField("HasNoLenses", "Add Lenses", "Filled", "Remove Lenses")
					:insertToggleField(
						"IsLensFocused",
						"Edit Edges",
						"Outline",
						nil,
						nil,
						nil,
						{ "HasNoLenses" :: CharacterEditorType.Tag }
					)
			end)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(newItemPage("Hoods", "costume", "hood", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build())
	:addChild(
		newItemPage("Shorts", "costume", "shorts", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build()
	)
	:addChild(newItemPage("Boots", "costume", "boots", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build())
	:addChild(newItemPage("Capes", "costume", "capes", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build())
	:addChild(newItemPage("Suit", "costume", "suit", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build())
	:addChild(
		newItemPage("Leg Armor", "costume", "leg-armor", newAccessoryPageBuilder):insertExclusionTag("IsSecret"):build()
	)
	:addChild(
		newItemPage("Glasses", "clothing", "glasses", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build()
	)
	:addChild(
		newItemPage("Gloves", "clothing", "gloves", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build()
	)
	:addChild(newItemPage("Hats", "clothing", "hats", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build())
	:addChild(
		newItemPage("Jackets", "clothing", "jackets", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build()
	)
	:addChild(newItemPage("Pants", "clothing", "pants", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build())
	:addChild(
		newItemPage("Shirts", "clothing", "shirts", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build()
	)
	:addChild(newItemPage("Shoes", "clothing", "shoes", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build())
	:addChild(newItemPage("Socks", "clothing", "socks", newAccessoryPageBuilder):insertExclusionTag("IsSuper"):build())
	:addChild(
		newItemPage("Accessories", "clothing", "accessories", newAccessoryPageBuilder)
			:insertExclusionTag("IsSuper")
			:build()
	)
	:addChild(PageBuilder.new("Eyebrows"):build())
	:addChild(PageBuilder.new("Eyes"):build())
	:addChild(newItemPage("Facial Hair", "cosmetics", "facial-hair", newAccessoryPageBuilder):build())
	:addChild(PageBuilder.new("Eyebrows"):build())
	:addChild(PageBuilder.new("Eyes"):build())
	:addChild(PageBuilder.new("Mouths"):build())
	:addChild(newItemPage("Hair", "cosmetics", "hair", newAccessoryPageBuilder):build())
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
	return table.concat(segments, "/")
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

return Module
