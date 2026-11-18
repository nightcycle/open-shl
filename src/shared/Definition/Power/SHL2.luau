--!strict
-- Services
-- Packages
-- Modules
local IconDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/IconDefinition")
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type EntitlementKey = EconomyType.EntitlementKey
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
type PowerCatalogue = PowerType.PowerCatalogue
type PowerDefinition = PowerType.PowerDefinition
type PowerGroup = PowerType.PowerGroup
-- Constants
local DEFAULT_LIMIT = 4
local PASS_LIMIT = 5
local PASS_ENTITLEMENT: EntitlementKey = "FifthPower"
-- the order the editor lists the groups in
local GROUPS: { PowerGroup } =
	table.freeze({ "basic-melee" :: PowerGroup, "advanced-melee", "ranged", "transportation", "special" })
-- no local image for this one
local PORTALS_ICON_ASSET_ID = 590433663
-- built from BrickColors so migrated saves match a choice
local BRIGHT_BLUE = BrickColor.new("Bright blue").Color
local BRIGHT_GREEN = BrickColor.new("Bright green").Color
local BRIGHT_ORANGE = BrickColor.new("Bright orange").Color
local BRIGHT_RED = BrickColor.new("Bright red").Color
local BRIGHT_VIOLET = BrickColor.new("Bright violet").Color
local BRIGHT_YELLOW = BrickColor.new("Bright yellow").Color
local CYAN = BrickColor.new("Cyan").Color
local DARK_GREEN = BrickColor.new("Dark green").Color
local DARK_STONE_GREY = BrickColor.new("Dark stone grey").Color
local INSTITUTIONAL_WHITE = BrickColor.new("Institutional white").Color
local LAPIS = BrickColor.new("Lapis").Color
local LIME_GREEN = BrickColor.new("Lime green").Color
local MAGENTA = BrickColor.new("Magenta").Color
local MEDIUM_STONE_GREY = BrickColor.new("Medium stone grey").Color
local NEW_YELLER = BrickColor.new("New Yeller").Color
local REALLY_BLACK = BrickColor.new("Really black").Color
local REALLY_RED = BrickColor.new("Really red").Color
local SHAMROCK = BrickColor.new("Shamrock").Color
-- the punch lists the fire colors in its own order
local FIRE_COLORS: { Color3 } =
	table.freeze({ BRIGHT_ORANGE, SHAMROCK, LAPIS, MAGENTA, REALLY_BLACK, INSTITUTIONAL_WHITE })
local FIRE_PUNCH_COLORS: { Color3 } =
	table.freeze({ BRIGHT_ORANGE, SHAMROCK, MAGENTA, REALLY_BLACK, INSTITUTIONAL_WHITE, LAPIS })
local METAL_COLORS: { Color3 } = table.freeze({
	BRIGHT_ORANGE,
	MEDIUM_STONE_GREY,
	BRIGHT_RED,
	REALLY_BLACK,
	BRIGHT_YELLOW,
	INSTITUTIONAL_WHITE,
	BRIGHT_GREEN,
	BRIGHT_BLUE,
	BRIGHT_VIOLET,
})
local ENERGY_COLORS: { Color3 } = table.freeze({
	REALLY_RED,
	CYAN,
	LAPIS,
	MAGENTA,
	INSTITUTIONAL_WHITE,
	REALLY_BLACK,
	NEW_YELLER,
	LIME_GREEN,
})
local BOW_COLORS: { Color3 } = table.freeze({
	DARK_GREEN,
	INSTITUTIONAL_WHITE,
	REALLY_BLACK,
	BRIGHT_RED,
	DARK_STONE_GREY,
	LAPIS,
	BRIGHT_YELLOW,
})
local ROPE_COLORS: { Color3 } = table.freeze({ REALLY_BLACK, INSTITUTIONAL_WHITE, DARK_STONE_GREY, MEDIUM_STONE_GREY })
local DEFINITIONS: { PowerDefinition } = {
	{
		Id = "basic-melee_bo-staff",
		Group = "basic-melee",
		Name = "Bo Staff",
		Icon = IconDefinitionConstructor.decal(Image.tools["bo-staff.png"]),
		EnergyCost = 12,
		Damage = 14,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_claws",
		Group = "basic-melee",
		Name = "Claws",
		Icon = IconDefinitionConstructor.decal(Image.tools["claws.png"]),
		EnergyCost = 16,
		Damage = 14,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_dual-katana",
		Group = "basic-melee",
		Name = "Dual Katanas",
		Icon = IconDefinitionConstructor.decal(Image.tools["dual-katana.png"]),
		EnergyCost = 16,
		Damage = 14,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_force-blast",
		Group = "basic-melee",
		Name = "Psychic Wave",
		Icon = IconDefinitionConstructor.decal(Image.tools["force-blast.png"]),
		EnergyCost = 12,
		Damage = 20,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_jungle-knife",
		Group = "basic-melee",
		Name = "Knife",
		Icon = IconDefinitionConstructor.decal(Image.tools["jungle-knife.png"]),
		EnergyCost = 12,
		Damage = 14,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_martial-arts",
		Group = "basic-melee",
		Name = "Martial Arts",
		Icon = IconDefinitionConstructor.decal(Image.tools["martial-arts.png"]),
		EnergyCost = 9,
		Damage = 13,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_hammer",
		Group = "basic-melee",
		Name = "Hammer",
		Icon = IconDefinitionConstructor.decal(Image.tools["hammer.png"]),
		EnergyCost = 12,
		Damage = 14,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_sword",
		Group = "basic-melee",
		Name = "Sword",
		Icon = IconDefinitionConstructor.decal(Image.tools["sword.png"]),
		EnergyCost = 12,
		Damage = 14,
		ColorGroups = {
			Primary = {
				Caption = "Sword Color",
				Default = MEDIUM_STONE_GREY,
				Choices = METAL_COLORS,
			},
		},
	},
	{
		Id = "basic-melee_trident",
		Group = "basic-melee",
		Name = "Trident",
		Icon = IconDefinitionConstructor.decal(Image.tools["trident.png"]),
		EnergyCost = 12,
		Damage = 14,
		ColorGroups = {
			Primary = {
				Caption = "Trident Color",
				Default = MEDIUM_STONE_GREY,
				Choices = METAL_COLORS,
			},
		},
	},
	{
		Id = "advanced-melee_tornado",
		Group = "advanced-melee",
		Name = "Tornado Spin",
		Icon = IconDefinitionConstructor.decal(Image.tools["tornado.png"]),
		EnergyCost = 85,
		Damage = 25,
		ColorGroups = {},
	},
	{
		Id = "advanced-melee_ice-storm",
		Group = "advanced-melee",
		Name = "Blizzard Spin",
		Icon = IconDefinitionConstructor.decal(Image.tools["ice-spike-spin.png"]),
		EnergyCost = 85,
		Damage = 32,
		ColorGroups = {},
	},
	{
		Id = "advanced-melee_fire-punch",
		Group = "advanced-melee",
		Name = "Inferno Punch",
		Icon = IconDefinitionConstructor.decal(Image.tools["fire-punch.png"]),
		EnergyCost = 60,
		Damage = 70,
		ColorGroups = {
			Primary = {
				Caption = "Fire Color",
				Default = BRIGHT_ORANGE,
				Choices = FIRE_PUNCH_COLORS,
			},
		},
	},
	{
		Id = "advanced-melee_force-explosion",
		Group = "advanced-melee",
		Name = "Psychic Boom",
		Icon = IconDefinitionConstructor.decal(Image.tools["force-shockwave.png"]),
		EnergyCost = 55,
		Damage = 32,
		ColorGroups = {},
	},
	{
		Id = "ranged_assault-gun",
		Group = "ranged",
		Name = "Assault Rifle",
		Icon = IconDefinitionConstructor.decal(Image.tools["machine-gun.png"]),
		EnergyCost = 15,
		Damage = 7,
		ColorGroups = {},
	},
	{
		Id = "ranged_fire-hand",
		Group = "ranged",
		Name = "Fire Blast",
		Icon = IconDefinitionConstructor.decal(Image.tools["fire-shoot.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {
			Primary = {
				Caption = "Fire Color",
				Default = BRIGHT_ORANGE,
				Choices = FIRE_COLORS,
			},
		},
	},
	{
		Id = "ranged_ice-hand",
		Group = "ranged",
		Name = "Ice Blast",
		Icon = IconDefinitionConstructor.decal(Image.tools["ice-shoot.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "ranged_laser-eyes",
		Group = "ranged",
		Name = "Laser Vision",
		Icon = IconDefinitionConstructor.decal(Image.tools["laser-eyes.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {
			Primary = {
				Caption = "Laser Color",
				Default = CYAN,
				Choices = ENERGY_COLORS,
			},
		},
	},
	{
		Id = "ranged_laser-hand",
		Group = "ranged",
		Name = "Laser Blast",
		Icon = IconDefinitionConstructor.decal(Image.tools["laser-hand.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {
			Primary = {
				Caption = "Laser Color",
				Default = CYAN,
				Choices = ENERGY_COLORS,
			},
		},
	},
	{
		Id = "ranged_lightning-hand",
		Group = "ranged",
		Name = "Lightning Blast",
		Icon = IconDefinitionConstructor.decal(Image.tools["lightning-shoot.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "ranged_magic-hand",
		Group = "ranged",
		Name = "Magic Blast",
		Icon = IconDefinitionConstructor.decal(Image.tools["magic-shoot.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {
			Primary = {
				Caption = "Magic Color",
				Default = LIME_GREEN,
				Choices = ENERGY_COLORS,
			},
		},
	},
	{
		Id = "ranged_bow",
		Group = "ranged",
		Name = "Bow",
		Icon = IconDefinitionConstructor.decal(Image.tools["arrows.png"]),
		EnergyCost = 35,
		Damage = 10,
		ColorGroups = {
			Primary = {
				Caption = "Bow Color",
				Default = REALLY_BLACK,
				Choices = BOW_COLORS,
			},
		},
	},
	{
		Id = "ranged_throwing-star",
		Group = "ranged",
		Name = "Throwing Star",
		Icon = IconDefinitionConstructor.decal(Image.tools["throwing-star.png"]),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {
			Primary = {
				Caption = "Star Color",
				Default = MEDIUM_STONE_GREY,
				Choices = METAL_COLORS,
			},
		},
	},
	{
		Id = "ranged_laser-gun",
		Group = "ranged",
		Name = "Laser Rifle",
		Icon = IconDefinitionConstructor.decal(Image.tools["laser-gun.png"]),
		EnergyCost = 15,
		Damage = 7,
		ColorGroups = {
			Primary = {
				Caption = "Laser Color",
				Default = CYAN,
				Choices = ENERGY_COLORS,
			},
		},
	},
	{
		Id = "ranged_handgun",
		Group = "ranged",
		Name = "Hand gun",
		Icon = IconDefinitionConstructor.decal(Image.tools["handgun.png"]),
		EnergyCost = 30,
		Damage = 14,
		ColorGroups = {},
	},
	{
		Id = "transportation_grapple",
		Group = "transportation",
		Name = "Grapple",
		Icon = IconDefinitionConstructor.decal(Image.tools["grapple-hook.png"]),
		EnergyCost = 18,
		Damage = 7,
		ColorGroups = {
			Primary = {
				Caption = "Rope Color",
				Default = MEDIUM_STONE_GREY,
				Choices = ROPE_COLORS,
			},
		},
	},
	{
		Id = "transportation_portals",
		Group = "transportation",
		Name = "Portals",
		Icon = IconDefinitionConstructor.decal(PORTALS_ICON_ASSET_ID),
		EnergyCost = 15,
		Damage = 15,
		ColorGroups = {
			Primary = {
				Caption = "Portal Color",
				Default = CYAN,
				Choices = ENERGY_COLORS,
			},
		},
	},
	{
		Id = "transportation_super-speed",
		Group = "transportation",
		Name = "Super Speed",
		Icon = IconDefinitionConstructor.decal(Image.tools["run.png"]),
		EnergyCost = 3,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_wall-climb",
		Group = "transportation",
		Name = "Wall Climbing",
		Icon = IconDefinitionConstructor.decal(Image.tools["wall-climb.png"]),
		EnergyCost = 6,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_flight",
		Group = "transportation",
		Name = "Flight",
		Icon = IconDefinitionConstructor.decal(Image.tools["flight.png"]),
		EnergyCost = 6,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_teleport",
		Group = "transportation",
		Name = "Teleport",
		Icon = IconDefinitionConstructor.decal(Image.tools["teleport.png"]),
		EnergyCost = 20,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "special_force-field",
		Group = "special",
		Name = "Force Field",
		Icon = IconDefinitionConstructor.decal(Image.tools["force-field.png"]),
		EnergyCost = 10,
		Damage = 0,
		ColorGroups = {
			Primary = {
				Caption = "Field Color",
				Default = CYAN,
				Choices = ENERGY_COLORS,
			},
		},
	},
	{
		Id = "special_healing-factor",
		Group = "special",
		Name = "Healing Factor",
		Icon = IconDefinitionConstructor.decal(Image.tools["heal.png"]),
		EnergyCost = 150,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_invisibility",
		Group = "special",
		Name = "Invisibility",
		Icon = IconDefinitionConstructor.decal(Image.tools["invisibility.png"]),
		EnergyCost = 90,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_invulnerability",
		Group = "special",
		Name = "Invulnerability",
		Icon = IconDefinitionConstructor.decal(Image.tools["invulnerability.png"]),
		EnergyCost = 90,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_camouflage",
		Group = "special",
		Name = "Camouflage",
		Icon = IconDefinitionConstructor.decal(Image.tools["camoflauge.png"]),
		EnergyCost = 45,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_mind-reading",
		Group = "special",
		Name = "Mind Read",
		Icon = IconDefinitionConstructor.decal(Image.tools["mind-reading.png"]),
		EnergyCost = 3,
		Damage = 0,
		ColorGroups = {},
	},
}
local CATALOGUE: PowerCatalogue = {
	Groups = GROUPS,
	Definitions = DEFINITIONS,
	DefaultLimit = DEFAULT_LIMIT,
	PassLimit = PASS_LIMIT,
	PassEntitlement = PASS_ENTITLEMENT,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
