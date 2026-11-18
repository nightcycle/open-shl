--!strict
-- Services
-- Packages
-- Modules
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local EditorPageDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor/Page")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
local getDeathStyleChoices = EditorPageDefinition.getDeathStyleChoices
local getPowerGroupChoices = EditorPageDefinition.getPowerGroupChoices
local getTransformationStyleChoices = EditorPageDefinition.getTransformationStyleChoices
local newAccessoryPageBuilder = EditorPageDefinition.newAccessoryPageBuilder
local newEmblemPageBuilder = EditorPageDefinition.newEmblemPageBuilder
local newItemPage = EditorPageDefinition.newItemPage
local newMaskPageBuilder = EditorPageDefinition.newMaskPageBuilder
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
type EditorDefinition = CharacterEditorType.EditorDefinition
type PageDefinition = CharacterEditorType.PageDefinition
type Tag = CharacterEditorType.Tag
-- Constants
local ROOT_KEY = EditorPageDefinition.ROOT_KEY
-- the server cuts a saved name + backstory down to the same lengths
local MAX_NAME_LENGTH = 30
local MAX_BACKSTORY_LENGTH = 150
local ROOT: PageDefinition = PageBuilder.new(ROOT_KEY)
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
local EDITOR: EditorDefinition = {
	MaxNameLength = MAX_NAME_LENGTH,
	MaxBackstoryLength = MAX_BACKSTORY_LENGTH,
	Root = ROOT,
}
-- Variables
-- References
-- Private Functions
-- Class
return EDITOR
