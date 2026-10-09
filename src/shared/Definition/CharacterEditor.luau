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
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
-- Constants
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
	local builder = PageBuilder.new("Chest Armor")
	for i, app in AppearanceItemDefinition.list(group, category) do
		builder = builder:addChild(fn(app):build())
	end
	return builder
end
function newAccessoryPageBuilder(itemDef: AppearanceType.ItemDefinition): PageBuilder
	return PageBuilder.newItem(itemDef.Id):insertColorField():insertMaterialField()
end
-- Class
local Module = {}

Module.DEFINITION = PageBuilder.new("ROOT")
	:addChild(PageBuilder.new("Basic Information")
		:addChild(PageBuilder.new("Name"):insertTextField(nil, 30):insertGenerateAliasField():build())
		:addChild(PageBuilder.new("Backstory"):insertTextField(nil, 120):build())
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
	local segments = path:split("/")
	assert(Module.DEFINITION.Type == "Default", `bad root page`)
	if segments[1] == Module.DEFINITION.Key then
		table.remove(segments, 1)
	end
	if segments[1] == "" then
		table.remove(segments, 1)
	end
	local function getPage(pageDef: PageDefinition, index: number): Option<PageDefinition>
		local segment = segments[index]
		if segment then
			if index == #segments then
				if pageDef.Type == "Default" and pageDef.Key == segment then
					return Option.some(pageDef)
				elseif pageDef.Type == "Item" and pageDef.DefinitionId == segment then
					return Option.some(pageDef)
				end
			elseif pageDef.Type == "Default" and pageDef.Children then
				for i, v in pageDef.Children do
					local childOpt = getPage(v, index + 1)
					if childOpt.IsSome then
						return childOpt
					end
				end
			end
		end
		return Option.none()
	end

	return getPage(Module.DEFINITION, 1)
end

return Module
