--!strict
-- Services
-- Packages
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local EditorPageDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor/Page")
local IconDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/IconDefinition")
local Image = require("@game/ReplicatedStorage/Generated/Image")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
local PatternDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Pattern")
local getPowerGroupChoices = EditorPageDefinition.getPowerGroupChoices
local newItemPage = EditorPageDefinition.newItemPage
-- Types
type PageBuilder = PageBuilder.Builder
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type ItemDefinition = AppearanceType.ItemDefinition
type ItemGroup = AppearanceType.ItemGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
type EditorDefinition = CharacterEditorType.EditorDefinition
type PageDefinition = CharacterEditorType.PageDefinition
type PatternChoice = CharacterEditorType.PatternChoice
type PowerColorSource = CharacterEditorType.PowerColorSource
type ScaleDefinition = CharacterEditorType.ScaleDefinition
type WearRule = CharacterEditorType.WearRule
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
-- Constants
local ROOT_KEY = EditorPageDefinition.ROOT_KEY
-- the server cuts a saved name + backstory down to the same lengths
local MAX_NAME_LENGTH = 20
local MAX_BACKSTORY_LENGTH = 140
-- five steps each. a width is how broad the body is for its height, so a taller body of the same build is a wider one
local SCALE: ScaleDefinition = table.freeze({
	Heights = table.freeze({ 0.75, 0.9, 1, 1.2, 1.4 }),
	WidthRatios = table.freeze({ 0.7, 0.8, 0.875, 0.935, 1 }),
	Default = table.freeze({ Height = 1, Width = 0.875 }),
})
local SUIT_GROUP: ItemGroup = "costume"
-- a power has no color of its own, whichever identity is out it wears the two main colors of the suit's torso
local POWER_COLOR_SOURCE: PowerColorSource = {
	IdentityKey = "Main",
	Group = SUIT_GROUP,
	Category = "suit-torso",
	Primary = "Primary",
	Secondary = "Secondary",
}
-- what a limb wears under a suit + once the suit is off, it's the limb in the base color. nobody picks it
local BODYSUIT_KEY = "bodysuit"
-- a suit piece calls its body layer the base, clothes are a main color + a detail
local SUIT_CAPTIONS: { [TextureGroupKey]: string } = table.freeze({
	Primary = "Primary",
	Secondary = "Secondary",
	Tertiary = "Base",
})
local CLOTHING_CAPTIONS: { [TextureGroupKey]: string } = table.freeze({
	Primary = "Main",
	Secondary = "Detail",
})
-- where the glow sits among the images of a pattern picker
local NEON_PATTERN_INDEX = 5
-- Variables
-- References
-- Private Functions
-- plain comes first, the glow is a material rather than an image
local function getPatternChoices(): { PatternChoice }
	local out: { PatternChoice } = {
		{ Name = "Plastic", Material = Enum.Material.SmoothPlastic },
	}
	for _, patternDef in PatternDefinition.list() do
		table.insert(out, {
			Name = patternDef.Name,
			Material = Enum.Material.SmoothPlastic,
			Pattern = patternDef.Key,
			Icon = IconDefinitionConstructor.decal(patternDef.Image),
		})
	end
	table.insert(out, NEON_PATTERN_INDEX, {
		Name = "Neon",
		Material = Enum.Material.Neon,
		Icon = IconDefinitionConstructor.decal(Image["shl-3"].ui["suit-creation"]["neon-swatch.png"]),
	})
	return out
end
-- the value of a choice is the number itself, the text is only its place in the row
local function getScaleChoices(values: { number }): { ChoiceDefinition }
	local out = {}
	for index, value in values do
		table.insert(out, ChoiceDefinitionConstructor.text(value, tostring(index)))
	end
	return out
end
-- worn or not, there's nothing about it to edit
local function newPlainPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	return PageBuilder.newItem(itemDef.Id, wearRule)
		:insertToggleField("IsItemAdded", "Add Item", "Filled", "Remove Item")
end
-- hair, eyes, a mouth + a beard are the character's, whichever identity is out
local function newSharedPlainPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	return newPlainPageBuilder(itemDef, wearRule):setShared()
end
-- one color, and nothing else: there's no material to a head of hair or to a pair of eyes
local function newSharedColorPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	local builder = newSharedPlainPageBuilder(itemDef, wearRule)
	local groupOpt = EditorPageDefinition.getMainTextureGroup(itemDef)
	if groupOpt.IsNone then
		return builder
	end
	return builder:insertColorField({ Type = "ItemTexture", Group = groupOpt.Value })
end
-- a color + a pattern for each of the groups the item has, under what its kind of item calls them
local function newPatternedPageBuilder(
	itemDef: ItemDefinition,
	wearRule: WearRule,
	captions: { [TextureGroupKey]: string }
): PageBuilder
	local builder = newPlainPageBuilder(itemDef, wearRule)
	for _, key: TextureGroupKey in itemDef.TextureGroups do
		local caption = captions[key]
		if caption == nil then
			continue
		end
		builder = builder
			:insertColorField({ Type = "ItemTexture", Group = key }, caption)
			:insertPatternField({ Type = "ItemTexture", Group = key }, `{caption} Pattern`)
	end
	return builder
end
local function newSuitPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	return newPatternedPageBuilder(itemDef, wearRule, SUIT_CAPTIONS)
end
local function newClothingPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	return newPatternedPageBuilder(itemDef, wearRule, CLOTHING_CAPTIONS)
end
-- the pieces of every suit that go on one limb, a character can wear a limb each of six suits
local function newLimbPage(key: string, category: string): PageBuilder
	local bodysuitId =
		AppearanceItemDefinition.getIdFromIndex({ Group = SUIT_GROUP, Category = category, Key = BODYSUIT_KEY })
	-- a head goes bare, it has no bodysuit
	local hasBodysuit = AppearanceItemDefinition.get(bodysuitId).IsOk
	local builder = PageBuilder.new(key)
	for _, itemDef in AppearanceItemDefinition.list(SUIT_GROUP, category) do
		if itemDef.Id == bodysuitId then
			continue
		end
		local pageBuilder = newSuitPageBuilder(itemDef, "Single")
		if hasBodysuit then
			pageBuilder = pageBuilder:setStandIn(bodysuitId)
		end
		builder = builder:addChild(pageBuilder:build())
	end
	return builder
end
-- Class
-- the pages are the tabs of the old editor, in its order + under its captions
local ROOT: PageDefinition = PageBuilder.new(ROOT_KEY)
	:addChild(
		PageBuilder.new("Hair")
			:addChild(newItemPage("Hair", "cosmetics", "hair", "Single", newSharedColorPageBuilder):build())
			:addChild(PageBuilder.new("Skin Color"):insertColorField({ Type = "SkinColor" }):build())
			:addChild(
				PageBuilder.new("Matching"):insertToggleField("IsColorMatched", "Combine", "Filled", "Separate"):build()
			)
			:build()
	)
	:addChild(
		PageBuilder.new("Face")
			:addChild(newItemPage("Eyes", "cosmetics", "eyes", "Single", newSharedColorPageBuilder):build())
			:addChild(newItemPage("Mouths", "cosmetics", "mouth", "Single", newSharedPlainPageBuilder):build())
			:build()
	)
	:addChild(
		PageBuilder.new("Clothing")
			:insertExclusionTag("IsSuper")
			:addChild(newItemPage("Shirts", "clothing", "shirts", "Single", newClothingPageBuilder):build())
			:addChild(newItemPage("Pants", "clothing", "pants", "Single", newClothingPageBuilder):build())
			:build()
	)
	:addChild(
		PageBuilder.new("Accessories")
			:addChild(
				newItemPage("Facial Hair", "cosmetics", "facial-hair", "Single", newSharedPlainPageBuilder):build()
			)
			:addChild(
				newItemPage("Hats", "clothing", "hats", "Single", newPlainPageBuilder)
					:insertExclusionTag("IsSuper")
					:build()
			)
			:addChild(
				newItemPage("Glasses", "clothing", "glasses", "Single", newPlainPageBuilder)
					:insertExclusionTag("IsSuper")
					:build()
			)
			:build()
	)
	:addChild(
		PageBuilder.new("Size")
			:addChild(
				PageBuilder.new("Body")
					:setShared()
					:insertChooseField({ Type = "Scale", Axis = "Height" }, getScaleChoices(SCALE.Heights), "HEIGHT")
					:insertChooseField({ Type = "Scale", Axis = "Width" }, getScaleChoices(SCALE.WidthRatios), "WEIGHT")
					:build()
			)
			:addChild(
				PageBuilder.new("Name")
					:insertTextField({ Type = "Profile", Key = "Name" }, "Insert name here", MAX_NAME_LENGTH)
					:build()
			)
			:build()
	)
	:addChild(
		PageBuilder.new("Suit")
			:insertExclusionTag("IsSecret")
			:addChild(newLimbPage("Head", "suit-head"):build())
			:addChild(newLimbPage("Torso", "suit-torso"):build())
			:addChild(newLimbPage("Left Arm", "suit-left-arm"):build())
			:addChild(newLimbPage("Right Arm", "suit-right-arm"):build())
			:addChild(newLimbPage("Left Leg", "suit-left-leg"):build())
			:addChild(newLimbPage("Right Leg", "suit-right-leg"):build())
			:addChild(newItemPage("Capes", SUIT_GROUP, "capes", "Single", newSuitPageBuilder):build())
			:addChild(newItemPage("Extras", SUIT_GROUP, "accessories", "Multi", newSuitPageBuilder):build())
			:build()
	)
	:addChild(
		newItemPage("Emblem", SUIT_GROUP, "emblems", "Single", newSuitPageBuilder)
			:insertExclusionTag("IsSecret")
			:build()
	)
	:addChild(
		PageBuilder.new("Powers")
			:insertSectionHeaderField("Choose Four Powers", { Type = "PowerLimit" })
			:insertChoiceListField(
				{ Type = "Powers", Group = "basic-melee" },
				getPowerGroupChoices("basic-melee"),
				"ATTACKS"
			)
			:insertChoiceListField({ Type = "Powers", Group = "ranged" }, getPowerGroupChoices("ranged"))
			:insertChoiceListField(
				{ Type = "Powers", Group = "transportation" },
				getPowerGroupChoices("transportation"),
				"EFFECTS"
			)
			:insertChoiceListField({ Type = "Powers", Group = "special" }, getPowerGroupChoices("special"))
			:build()
	)
	:addChild(
		PageBuilder.new("Backstory")
			:setShared()
			:insertTextField(
				{ Type = "Profile", Key = "Backstory" },
				"Insert your character's story here!",
				MAX_BACKSTORY_LENGTH,
				true
			)
			:build()
	)
	:build()
local EDITOR: EditorDefinition = {
	MaxNameLength = MAX_NAME_LENGTH,
	MaxBackstoryLength = MAX_BACKSTORY_LENGTH,
	Scale = SCALE,
	PatternChoices = getPatternChoices(),
	PowerColorSource = POWER_COLOR_SOURCE,
	-- a color was the slot's in the old game, not the piece's: it stayed through another suit, shirt or head of hair
	IsLookKept = true,
	Root = ROOT,
}
return EDITOR
