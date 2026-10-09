--!strict
-- Services
-- Packages
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
-- Types
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
	:addChild(PageBuilder.new("Hoods"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Shorts"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Boots"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Capes"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Suit"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Leg Armor"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Glasses"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Gloves"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Hats"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Jackets"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Pants"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Shirt"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Shoes"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Socks"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Accessories"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Eyebrows"):build())
	:addChild(PageBuilder.new("Eyes"):build())
	:addChild(PageBuilder.new("Facial Hair"):build())
	:addChild(PageBuilder.new("Eyebrows"):build())
	:addChild(PageBuilder.new("Eyes"):build())
	:addChild(PageBuilder.new("Mouths"):build())
	:addChild(PageBuilder.new("Hair"):build())
	:build()

function Module.getPage() end

return Module
