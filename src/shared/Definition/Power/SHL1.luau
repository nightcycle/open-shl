--!strict
-- Services
-- Packages
-- Modules
local IconDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/IconDefinition")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
type PowerCatalogue = PowerType.PowerCatalogue
type PowerDefinition = PowerType.PowerDefinition
type PowerGroup = PowerType.PowerGroup
type PowerSlot = PowerType.PowerSlot
-- Constants
-- one power of each slot at most, so three. no pass raises it: the pass of this game is for powers, not for room
local DEFAULT_LIMIT = 3
local PASS_LIMIT = 3
-- only the hero has them, the secret identity carries none
local IDENTITY_KEY: IdentityKey = "Main"
-- the order the editor lists the groups in
local GROUPS: { PowerGroup } = table.freeze({ "basic-melee" :: PowerGroup, "ranged", "transportation", "special" })
-- a tool of this game never had a picture, the hotbar spells its name
local NO_ICON = IconDefinitionConstructor.decal("")
-- nothing here costs energy + none has a color of its own. a hit takes off what its power says
local DEFINITIONS: { PowerDefinition } = {
	{
		Id = "basic-melee_bo-staff",
		Group = "basic-melee",
		Name = "Bo Staff",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 20,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_martial-arts",
		Group = "basic-melee",
		Name = "Martial Arts",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "ranged_bow",
		Group = "ranged",
		Name = "Bow",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "ranged_fire-hand",
		Group = "ranged",
		Name = "Fire",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 34,
		ColorGroups = {},
	},
	-- whoever its ice reaches is held for a while as well
	{
		Id = "ranged_ice-charge",
		Group = "ranged",
		Name = "Ice",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 20,
		ColorGroups = {},
	},
	-- a throw is up to five of these
	{
		Id = "ranged_kunai",
		Group = "ranged",
		Name = "Kunai",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 25,
		ColorGroups = {},
	},
	{
		Id = "ranged_laser-ray",
		Group = "ranged",
		Name = "Laser Blast",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 20,
		ColorGroups = {},
	},
	-- a ray from each eye, for as long as it's held
	{
		Id = "ranged_laser-vision",
		Group = "ranged",
		Name = "Laser Vision",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 3,
		ColorGroups = {},
	},
	{
		Id = "ranged_lightning-hand",
		Group = "ranged",
		Name = "Lightning",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 34,
		ColorGroups = {},
	},
	{
		Id = "ranged_machine-gun",
		Group = "ranged",
		Name = "Machine Gun",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "ranged_returning-star",
		Group = "ranged",
		Name = "Throwing Star",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "transportation_flight",
		Group = "transportation",
		Name = "Fly",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_super-speed",
		Group = "transportation",
		Name = "Super Speed",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_grapple",
		Group = "transportation",
		Name = "Grappling Hook",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_super-jump",
		Group = "transportation",
		Name = "Super Jump",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	-- it takes nothing off, what it hits gets 20 back
	{
		Id = "special_healing-ray",
		Group = "special",
		Name = "Healing",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_invisibility",
		Group = "special",
		Name = "Invisibility",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
}
-- a row moves up into the list above once both halves of its ability are in the game's set
local UPCOMING: { PowerDefinition } = {
	{
		Id = "basic-melee_katana",
		Group = "basic-melee",
		Name = "Katana",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 35,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_sai",
		Group = "basic-melee",
		Name = "Sai",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 15,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_hammer",
		Group = "basic-melee",
		Name = "Hammer",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 25,
		ColorGroups = {},
	},
	{
		Id = "special_energy-field",
		Group = "special",
		Name = "Energy Field",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_portals",
		Group = "transportation",
		Name = "Portal",
		Icon = NO_ICON,
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
}
-- the three lists of the old creator, each in its order: a hero takes one of each or goes without. what gets the
-- hero around was a special there, so those sit in a slot that isn't their group. the first of each list were
-- anybody's, the rest are behind the one pass of the powers: a lock a slot, so each is rented + kept by itself
local SLOTS: { PowerSlot } = {
	{
		Key = "Melee",
		Caption = "MELEE",
		StarterCount = 3,
		Lock = { Id = "melee", Type = "Entitlement", Key = "PremiumPowers", RentPrice = 30 },
		PowerIds = {
			"basic-melee_bo-staff",
			"basic-melee_martial-arts",
			"basic-melee_katana",
			"basic-melee_sai",
			"basic-melee_hammer",
		},
	},
	{
		Key = "Ranged",
		Caption = "RANGED",
		StarterCount = 5,
		Lock = { Id = "ranged", Type = "Entitlement", Key = "PremiumPowers", RentPrice = 30 },
		PowerIds = {
			"ranged_bow",
			"ranged_fire-hand",
			"ranged_ice-charge",
			"ranged_laser-ray",
			"ranged_laser-vision",
			"ranged_returning-star",
			"ranged_kunai",
			"ranged_lightning-hand",
			"ranged_machine-gun",
		},
	},
	{
		Key = "Special",
		Caption = "SPECIAL",
		StarterCount = 3,
		Lock = { Id = "special", Type = "Entitlement", Key = "PremiumPowers", RentPrice = 30 },
		PowerIds = {
			"transportation_flight",
			"transportation_super-speed",
			"transportation_grapple",
			"special_energy-field",
			"special_healing-ray",
			"special_invisibility",
			"transportation_super-jump",
			"transportation_portals",
		},
	},
}
local CATALOGUE: PowerCatalogue = {
	Groups = GROUPS,
	Definitions = DEFINITIONS,
	Upcoming = UPCOMING,
	Slots = SLOTS,
	IdentityKey = IDENTITY_KEY,
	DefaultLimit = DEFAULT_LIMIT,
	PassLimit = PASS_LIMIT,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
