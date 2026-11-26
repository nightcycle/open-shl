--!strict
-- Services
-- Packages
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ChoiceDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/ChoiceDefinition")
local EditorPageDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor/Page")
local PageBuilder = require("@game/ReplicatedStorage/Shared/Builder/CharacterEditorPageDefinition")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
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
type WearRule = CharacterEditorType.WearRule
type WornTextureBinding = CharacterEditorType.WornTextureBinding
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
type PowerSlot = PowerType.PowerSlot
-- Constants
local ROOT_KEY = EditorPageDefinition.ROOT_KEY
-- the old creator cut a name nowhere, the server cuts a saved one down to this
local MAX_NAME_LENGTH = 30
-- nobody has a backstory here, whatever is sent for one is emptied
local MAX_BACKSTORY_LENGTH = 0
-- what a name that was left empty turned into: the name of the account + the same with a "Super" in front
local NAME_DEFAULTS: { [IdentityKey]: string } = table.freeze({
	Main = "Super %s",
	Secret = "%s",
})
local SUIT_GROUP: ItemGroup = "costume"
local SUIT_TORSO_CATEGORY = "suit-torso"
-- a suit is its torso + these, a hero wears a limb each of up to five suits
local SUIT_LIMB_CATEGORIES: { string } =
	table.freeze({ "suit-left-arm", "suit-right-arm", SUIT_TORSO_CATEGORY, "suit-left-leg", "suit-right-leg" })
-- the 64 colors of the old creator's grid, row by row. skin, hair + the three colors of a costume are each one of
-- these. built from BrickColors so a save that's brought over matches a choice
local PALETTE: { Color3 } = table.freeze({
	BrickColor.new(119).Color, -- Br. yellowish green
	BrickColor.new(24).Color, -- Bright yellow
	BrickColor.new(106).Color, -- Bright orange
	BrickColor.new(21).Color, -- Bright red
	BrickColor.new(104).Color, -- Bright violet
	BrickColor.new(23).Color, -- Bright blue
	BrickColor.new(107).Color, -- Bright bluish green
	BrickColor.new(37).Color, -- Bright green
	BrickColor.new(1001).Color, -- Institutional white
	BrickColor.new(1).Color, -- White
	BrickColor.new(208).Color, -- Light stone grey
	BrickColor.new(1002).Color, -- Mid gray
	BrickColor.new(194).Color, -- Medium stone grey
	BrickColor.new(199).Color, -- Dark stone grey
	BrickColor.new(26).Color, -- Black
	BrickColor.new(1003).Color, -- Really black
	BrickColor.new(1022).Color, -- Grime
	BrickColor.new(105).Color, -- Br. yellowish orange
	BrickColor.new(125).Color, -- Light orange
	BrickColor.new(153).Color, -- Sand red
	BrickColor.new(1023).Color, -- Lavender
	BrickColor.new(135).Color, -- Sand blue
	BrickColor.new(102).Color, -- Medium blue
	BrickColor.new(151).Color, -- Sand green
	BrickColor.new(5).Color, -- Brick yellow
	BrickColor.new(226).Color, -- Cool yellow
	BrickColor.new(133).Color, -- Neon orange
	BrickColor.new(101).Color, -- Medium red
	BrickColor.new(9).Color, -- Light reddish violet
	BrickColor.new(11).Color, -- Pastel Blue
	BrickColor.new(1018).Color, -- Teal
	BrickColor.new(29).Color, -- Medium green
	BrickColor.new(1030).Color, -- Pastel brown
	BrickColor.new(1029).Color, -- Pastel yellow
	BrickColor.new(1025).Color, -- Pastel orange
	BrickColor.new(1016).Color, -- Pink
	BrickColor.new(1026).Color, -- Pastel violet
	BrickColor.new(1024).Color, -- Pastel light blue
	BrickColor.new(1027).Color, -- Pastel blue-green
	BrickColor.new(1028).Color, -- Pastel green
	BrickColor.new(1008).Color, -- Olive
	BrickColor.new(1009).Color, -- New Yeller
	BrickColor.new(1005).Color, -- Deep orange
	BrickColor.new(1004).Color, -- Really red
	BrickColor.new(1032).Color, -- Hot pink
	BrickColor.new(1010).Color, -- Really blue
	BrickColor.new(1019).Color, -- Toothpaste
	BrickColor.new(1020).Color, -- Lime green
	BrickColor.new(217).Color, -- Brown
	BrickColor.new(18).Color, -- Nougat
	BrickColor.new(38).Color, -- Dark orange
	BrickColor.new(1031).Color, -- Royal purple
	BrickColor.new(1006).Color, -- Alder
	BrickColor.new(1013).Color, -- Cyan
	BrickColor.new(45).Color, -- Light blue
	BrickColor.new(1021).Color, -- Camo
	BrickColor.new(192).Color, -- Reddish brown
	BrickColor.new(1014).Color, -- CGA brown
	BrickColor.new(1007).Color, -- Dusty Rose
	BrickColor.new(1015).Color, -- Magenta
	BrickColor.new(1012).Color, -- Deep blue
	BrickColor.new(1011).Color, -- Navy blue
	BrickColor.new(28).Color, -- Dark green
	BrickColor.new(141).Color, -- Earth green
})
-- two tools were drawn in the colors of the chest piece, whoever held them. every other came in its own
local POWER_COLOR_SOURCE: PowerColorSource = {
	IdentityKey = "Main",
	Group = SUIT_GROUP,
	Category = SUIT_TORSO_CATEGORY,
	Primary = "Primary",
	Secondary = "Secondary",
	PowerIds = { "ranged_laser-ray", "special_energy-field" },
}
-- what the old creator wore a costume + a head of hair in until a color was picked: two greys, a white + black
local CHANNEL_DEFAULTS: { [TextureGroupKey]: Color3 } = table.freeze({
	Primary = BrickColor.new(194).Color,
	Secondary = BrickColor.new(1002).Color,
	Tertiary = BrickColor.new(1001).Color,
	Hair = BrickColor.new(26).Color,
})
-- a color of the costume glows or it doesn't, there's no image to draw over one
local PATTERN_CHOICES: { PatternChoice } = table.freeze({
	table.freeze({ Name = "Plastic", Material = Enum.Material.SmoothPlastic }),
	table.freeze({ Name = "Neon", Material = Enum.Material.Neon }),
})
-- Variables
-- References
-- Private Functions
-- worn or not, there's nothing about it to edit: its colors are the costume's or the character's
local function newPlainPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	return PageBuilder.newItem(itemDef.Id, wearRule):insertToggleField("IsItemAdded", "Add", "Filled", "Remove")
end
-- a face + a head of hair are the character's, whichever identity is out
local function newSharedPlainPageBuilder(itemDef: ItemDefinition, wearRule: WearRule): PageBuilder
	return newPlainPageBuilder(itemDef, wearRule):setShared()
end
-- the items of a category that are on its list, in the order of the list. what the list leaves out isn't offered
local function newListPage(
	key: string,
	group: ItemGroup,
	category: string,
	wearRule: WearRule,
	fn: (ItemDefinition, WearRule) -> PageBuilder
): PageBuilder
	local builder = PageBuilder.new(key)
	for _, itemDef in AppearanceItemDefinition.list(group, category) do
		if itemDef.Order == nil then
			continue
		end
		builder = builder:addChild(fn(itemDef, wearRule):build())
	end
	return builder
end
-- every suit whole: its torso + its four limbs go on at once, the way the first row of the old page dressed a hero
local function newSuitSetsPage(key: string): PageBuilder
	local builder = PageBuilder.new(key)
	for _, torsoDef in AppearanceItemDefinition.list(SUIT_GROUP, SUIT_TORSO_CATEGORY) do
		if torsoDef.Order == nil then
			continue
		end
		local indexRes = AppearanceItemDefinition.getIndex(torsoDef.Id)
		assert(indexRes.IsOk, indexRes.Value)
		local suitKey = indexRes.Value.Key
		local definitionIds: { string } = {}
		for _, category in SUIT_LIMB_CATEGORIES do
			local id =
				AppearanceItemDefinition.getIdFromIndex({ Group = SUIT_GROUP, Category = category, Key = suitKey })
			-- a suit that's short of a limb is one the checker lets through
			assert(AppearanceItemDefinition.get(id).IsOk, `the "{suitKey}" suit has no "{category}"`)
			table.insert(definitionIds, id)
		end
		builder = builder:addChild(
			PageBuilder.newSet(suitKey, definitionIds)
				:setTitle(torsoDef.Name)
				:insertToggleField("IsItemAdded", "Add", "Filled", "Remove")
				:build()
		)
	end
	return builder
end
-- one color or one glow for everything the hero wears of the costume, + one color for whatever hair there is
local function newWornBinding(itemGroup: ItemGroup, group: TextureGroupKey): WornTextureBinding
	return { Type = "WornTexture", ItemGroup = itemGroup, Group = group }
end
-- a tool had no picture, a list spells the names
local function getPowerSlotChoices(slot: PowerSlot): { ChoiceDefinition }
	local out = {}
	for _, id in slot.PowerIds do
		local powerDefRes = PowerDefinition.get(id)
		assert(powerDefRes.IsOk, powerDefRes.Value)
		table.insert(out, ChoiceDefinitionConstructor.text(id, powerDefRes.Value.Name))
	end
	return out
end
-- a list for each of the game's slots, under what the slot is called
local function newPowersPage(key: string): PageBuilder
	local builder = PageBuilder.new(key)
	for _, slot in PowerDefinition.listSlots() do
		builder = builder:insertChoiceListField(
			{ Type = "PowerSlot", Slot = slot.Key },
			getPowerSlotChoices(slot),
			slot.Caption
		)
	end
	return builder
end
-- Class
-- the pages are the frames of the old creator, in the order it walked them + under its titles. the first + the last
-- edit nothing of the character: what the group gives away, + whether the player fights
local ROOT: PageDefinition = PageBuilder
	.new(ROOT_KEY)
	:addChild(PageBuilder.newStep("Promo"):setTitle("GET FREE STUFF!"):build())
	:addChild(
		PageBuilder.new("Secret Identity")
			:insertExclusionTag("IsSuper")
			:addChild(newListPage("FACES", "cosmetics", "face", "Single", newSharedPlainPageBuilder):build())
			:addChild(newListPage("HAIR", "cosmetics", "hair", "Single", newSharedPlainPageBuilder):build())
			:build()
	)
	-- skin + hair are picked once for both identities
	:addChild(
		PageBuilder.new("Colors")
			:insertExclusionTag("IsSuper")
			:setShared()
			:insertColorField({ Type = "SkinColor" }, "SKIN COLOR")
			:insertColorField(newWornBinding("cosmetics", "Hair"), "HAIR COLOR")
			:build()
	)
	-- a hero is let go of once it wears a torso, the limbs can stay bare
	:addChild(
		PageBuilder.new("Costume")
			:insertExclusionTag("IsSecret")
			:setRequirement({ Group = SUIT_GROUP, Category = SUIT_TORSO_CATEGORY, Text = "Get a suit!" })
			:addChild(newSuitSetsPage("SUITS"):build())
			:addChild(newListPage("LEFT ARM", SUIT_GROUP, "suit-left-arm", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("RIGHT ARM", SUIT_GROUP, "suit-right-arm", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("TORSO", SUIT_GROUP, SUIT_TORSO_CATEGORY, "Single", newPlainPageBuilder):build())
			:addChild(newListPage("LEFT LEG", SUIT_GROUP, "suit-left-leg", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("RIGHT LEG", SUIT_GROUP, "suit-right-leg", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("CAPES", SUIT_GROUP, "capes", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("MASKS", SUIT_GROUP, "hats", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("EMBLEMS", SUIT_GROUP, "emblems", "Single", newPlainPageBuilder):build())
			:addChild(newListPage("OTHER", SUIT_GROUP, "extras", "Multi", newPlainPageBuilder):build())
			:build()
	)
	:addChild(
		PageBuilder.new("Costume Colors")
			:insertExclusionTag("IsSecret")
			:insertColorField(newWornBinding(SUIT_GROUP, "Primary"), "PRIMARY")
			:insertColorField(newWornBinding(SUIT_GROUP, "Secondary"), "SECONDARY")
			:insertColorField(newWornBinding(SUIT_GROUP, "Tertiary"), "TERTIARY")
			:build()
	)
	:addChild(
		PageBuilder.new("Neon Elements")
			:insertExclusionTag("IsSecret")
			:insertPatternField(newWornBinding(SUIT_GROUP, "Primary"), "Primary")
			:insertPatternField(newWornBinding(SUIT_GROUP, "Secondary"), "Secondary")
			:insertPatternField(newWornBinding(SUIT_GROUP, "Tertiary"), "Tertiary")
			:build()
	)
	:addChild(newPowersPage("Abilities"):build())
	-- one of three, where the other games have two axes
	:addChild(PageBuilder.new("Alignment")
		:insertChooseField({ Type = "Alignment", Axis = "Morality" }, {
			ChoiceDefinitionConstructor.text("Good", "HERO"),
			ChoiceDefinitionConstructor.text("Evil", "VILLAIN"),
			ChoiceDefinitionConstructor.text("Neutral", "OTHER"),
		})
		:build())
	-- both names on one page, whichever identity is in focus
	:addChild(
		PageBuilder.new("Naming")
			:insertTextField(
				{ Type = "Profile", Key = "Name", IdentityKey = "Secret" },
				"Enter your average name Here!",
				MAX_NAME_LENGTH
			)
			:insertTextField(
				{ Type = "Profile", Key = "Name", IdentityKey = "Main" },
				"Enter your super name Here!",
				MAX_NAME_LENGTH
			)
			:build()
	)
	:addChild(PageBuilder.newStep("Mode"):build())
	:build()
local EDITOR: EditorDefinition = {
	MaxNameLength = MAX_NAME_LENGTH,
	MaxBackstoryLength = MAX_BACKSTORY_LENGTH,
	PatternChoices = PATTERN_CHOICES,
	PowerColorSource = POWER_COLOR_SOURCE,
	Palette = PALETTE,
	ChannelDefaults = CHANNEL_DEFAULTS,
	NameDefaults = NAME_DEFAULTS,
	Root = ROOT,
}
return EDITOR
