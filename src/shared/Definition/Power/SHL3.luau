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
local PASS_LIMIT = 6
local PASS_ENTITLEMENT: EntitlementKey = "ExtraPowers"
-- the order the editor lists the groups in: its attacks, then its effects
local GROUPS: { PowerGroup } = table.freeze({ "basic-melee" :: PowerGroup, "ranged", "transportation", "special" })
-- nothing here costs energy + none has a color of its own: a power is on a cooldown + wears the colors of the suit.
-- the damage is what a hit takes off before the game's own rule for a hit on a player
local DEFINITIONS: { PowerDefinition } = {
	{
		Id = "basic-melee_martial-arts",
		Group = "basic-melee",
		Name = "Martial Arts",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["martial-arts.png"]),
		EnergyCost = 0,
		Damage = 25,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_dual-katana",
		Group = "basic-melee",
		Name = "Katanas",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["katanas.png"]),
		EnergyCost = 0,
		Damage = 17,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_claws",
		Group = "basic-melee",
		Name = "Claws",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["claws.png"]),
		EnergyCost = 0,
		Damage = 30,
		ColorGroups = {},
	},
	{
		Id = "ranged_laser-ray",
		Group = "ranged",
		Name = "Laser Ray",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["laser-ray.png"]),
		EnergyCost = 0,
		Damage = 10,
		ColorGroups = {},
	},
	{
		Id = "transportation_flight",
		Group = "transportation",
		Name = "Flight",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["flight.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_super-speed",
		Group = "transportation",
		Name = "Super Speed",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["super-speed.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_invisibility",
		Group = "special",
		Name = "Invisibility",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["invisibility.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
}
-- a row moves up into the list above once both halves of its ability are in the game's set
local UPCOMING: { PowerDefinition } = {
	{
		Id = "basic-melee_bo-staff",
		Group = "basic-melee",
		Name = "Bo Staff",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["bo-staff.png"]),
		EnergyCost = 0,
		Damage = 20,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_hammer",
		Group = "basic-melee",
		Name = "Hammer",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["hammer.png"]),
		EnergyCost = 0,
		Damage = 30,
		ColorGroups = {},
	},
	{
		Id = "basic-melee_sword",
		Group = "basic-melee",
		Name = "Sword",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["sword.png"]),
		EnergyCost = 0,
		Damage = 20,
		ColorGroups = {},
	},
	{
		Id = "ranged_hitscan-bow",
		Group = "ranged",
		Name = "Bow",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["bow.png"]),
		EnergyCost = 0,
		Damage = 28,
		ColorGroups = {},
	},
	-- what it deals is a burn, not a hit
	{
		Id = "ranged_fire-ray",
		Group = "ranged",
		Name = "Fire Ray",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["fire-ray.png"]),
		EnergyCost = 0,
		Damage = 35,
		ColorGroups = {},
	},
	{
		Id = "ranged_freeze-ray",
		Group = "ranged",
		Name = "Freeze Ray",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["freeze-ray.png"]),
		EnergyCost = 0,
		Damage = 20,
		ColorGroups = {},
	},
	{
		Id = "ranged_lightning",
		Group = "ranged",
		Name = "Lightning",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["lightning.png"]),
		EnergyCost = 0,
		Damage = 17,
		ColorGroups = {},
	},
	-- a click is four of these
	{
		Id = "ranged_minigun",
		Group = "ranged",
		Name = "Minigun",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["minigun.png"]),
		EnergyCost = 0,
		Damage = 10,
		ColorGroups = {},
	},
	{
		Id = "transportation_grapple",
		Group = "transportation",
		Name = "Grapple Hook",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["grapple-hook.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_super-jump",
		Group = "transportation",
		Name = "Super Jump",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["super-jump.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "transportation_teleport",
		Group = "transportation",
		Name = "Teleport",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["teleport.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_force-shield",
		Group = "special",
		Name = "Force Field",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["force-field.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_mind-reading",
		Group = "special",
		Name = "Mind Reading",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["mind-reading.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
	{
		Id = "special_x-ray-vision",
		Group = "special",
		Name = "X-Ray Vision",
		Icon = IconDefinitionConstructor.decal(Image.shl3.tools["x-ray-vision.png"]),
		EnergyCost = 0,
		Damage = 0,
		ColorGroups = {},
	},
}
local CATALOGUE: PowerCatalogue = {
	Groups = GROUPS,
	Definitions = DEFINITIONS,
	Upcoming = UPCOMING,
	DefaultLimit = DEFAULT_LIMIT,
	PassLimit = PASS_LIMIT,
	PassEntitlement = PASS_ENTITLEMENT,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
