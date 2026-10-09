--!strict
-- Services
-- Packages
-- Modules
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
-- Types
type PageBuilder = PageBuilder.Builder
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
-- Constants
local NAME_PAGE = PageBuilder.new("Name"):insertTextField(nil, 30):insertGenerateAliasField():build()
local BACKSTORY_PAGE = PageBuilder.new("Backstory"):insertTextField(nil, 120):build()
local ALIGNMENT_PAGE = PageBuilder.new("Alignment")
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
	:build()
local DEATH_STYLE_PAGE = PageBuilder.new("Death Style")
	:insertChooseField({
		ChoiceDefinitionConstructor.text("Fall Backwards"),
		ChoiceDefinitionConstructor.text("Fall Forwards"),
	}, "Choose a Death Style")
	:build()
local TRANSFORMATION_STYLE_PAGE = PageBuilder.new("Transformation Style")
	:insertChooseField({
		ChoiceDefinitionConstructor.text("Ascension"),
		ChoiceDefinitionConstructor.text("Spin"),
		ChoiceDefinitionConstructor.text("Fire"),
		ChoiceDefinitionConstructor.text("Smoke"),
	}, "Choose a Transformation Style")
	:build()
-- Variables
-- References
-- Private Functions
function getPowerGroupChoices(
	group: "basic-melee" | "advanced-melee" | "ranged" | "transportation" | "special"
): { ChoiceDefinition }
	return {}
end
-- Class
local Module = {}

Module.DEFINITION = PageBuilder
	.new("ROOT")
	:addChild(
		PageBuilder.new("Basic Information")
			:addChild(NAME_PAGE)
			:addChild(BACKSTORY_PAGE)
			:addChild(ALIGNMENT_PAGE)
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
			:addChild(DEATH_STYLE_PAGE)
			:addChild(TRANSFORMATION_STYLE_PAGE)
			:build()
	)
	-- super
	:addChild(PageBuilder.new("Arm Armor"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Chest Armor"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Emblems"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Mouth Covers"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Masks"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Hoods"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Shorts"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Boots"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Capes"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Suit"):insertExclusionTag("IsSecret"):build())
	:addChild(PageBuilder.new("Leg Armor"):insertExclusionTag("IsSecret"):build())
	-- secret
	:addChild(PageBuilder.new("Glasses"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Gloves"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Hats"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Jackets"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Pants"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Shirt"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Shoes"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Socks"):insertExclusionTag("IsSuper"):build())
	:addChild(PageBuilder.new("Accessories"):insertExclusionTag("IsSuper"):build())
	-- generic
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
