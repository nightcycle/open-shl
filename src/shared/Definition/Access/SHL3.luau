--!strict
-- Services
-- Packages
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type AccessCatalogue = EconomyType.AccessCatalogue
type Listing = EconomyType.Listing
-- Constants
-- what the old place multiplied every cost by. the script that drew it anew for each server (1.5 to 2) was switched
-- off, this is the number it was left at
local PRICE_ADJUST = 1.675
-- everything that was sold or had to be picked up: an entry of the catalogue nobody starts out with, at the cost the
-- old place stored for it, + the powers that had one. the four without a cost were had for nothing, by whoever
-- pressed purchase on them. an id is the folder the old place kept it in + its name
local LISTINGS: { Listing } = {
	{
		Id = "suits_assassin-suit",
		Name = "Assassin Suit",
		Cost = 7_725,
		ItemIds = {
			"costume_suit-head_assassin-suit",
			"costume_suit-torso_assassin-suit",
			"costume_suit-left-arm_assassin-suit",
			"costume_suit-right-arm_assassin-suit",
			"costume_suit-left-leg_assassin-suit",
			"costume_suit-right-leg_assassin-suit",
		},
	},
	{
		Id = "suits_cosmic-suit",
		Name = "Cosmic Suit",
		Cost = 23_670,
		ItemIds = {
			"costume_suit-head_cosmic-suit",
			"costume_suit-torso_cosmic-suit",
			"costume_suit-left-arm_cosmic-suit",
			"costume_suit-right-arm_cosmic-suit",
			"costume_suit-left-leg_cosmic-suit",
			"costume_suit-right-leg_cosmic-suit",
		},
	},
	{
		Id = "suits_covert-suit",
		Name = "Covert Suit",
		Cost = 4_238,
		ItemIds = {
			"costume_suit-head_covert-suit",
			"costume_suit-torso_covert-suit",
			"costume_suit-left-arm_covert-suit",
			"costume_suit-right-arm_covert-suit",
			"costume_suit-left-leg_covert-suit",
			"costume_suit-right-leg_covert-suit",
		},
	},
	{
		Id = "suits_espionage-suit",
		Name = "Espionage Suit",
		Cost = 4_238,
		ItemIds = {
			"costume_suit-head_espionage-suit",
			"costume_suit-torso_espionage-suit",
			"costume_suit-left-arm_espionage-suit",
			"costume_suit-right-arm_espionage-suit",
			"costume_suit-left-leg_espionage-suit",
			"costume_suit-right-leg_espionage-suit",
		},
	},
	{
		Id = "suits_heavy-suit",
		Name = "Heavy Suit",
		Cost = 0,
		ItemIds = {
			"costume_suit-head_heavy-suit",
			"costume_suit-torso_heavy-suit",
			"costume_suit-left-arm_heavy-suit",
			"costume_suit-right-arm_heavy-suit",
			"costume_suit-left-leg_heavy-suit",
			"costume_suit-right-leg_heavy-suit",
		},
	},
	{
		Id = "suits_magician-suit",
		Name = "Magician Suit",
		Cost = 4_238,
		ItemIds = {
			"costume_suit-head_magician-suit",
			"costume_suit-torso_magician-suit",
			"costume_suit-left-arm_magician-suit",
			"costume_suit-right-arm_magician-suit",
			"costume_suit-left-leg_magician-suit",
			"costume_suit-right-leg_magician-suit",
		},
	},
	{
		Id = "suits_psycho-suit",
		Name = "Psycho Suit",
		Cost = 8_175,
		ItemIds = {
			"costume_suit-head_psycho-suit",
			"costume_suit-torso_psycho-suit",
			"costume_suit-left-arm_psycho-suit",
			"costume_suit-right-arm_psycho-suit",
			"costume_suit-left-leg_psycho-suit",
			"costume_suit-right-leg_psycho-suit",
		},
	},
	{
		Id = "suits_twilight-suit",
		Name = "Twilight Suit",
		Cost = 4_238,
		ItemIds = {
			"costume_suit-head_twilight-suit",
			"costume_suit-torso_twilight-suit",
			"costume_suit-left-arm_twilight-suit",
			"costume_suit-right-arm_twilight-suit",
			"costume_suit-left-leg_twilight-suit",
			"costume_suit-right-leg_twilight-suit",
		},
	},
	{ Id = "shirts_jersey", Name = "Jersey", Cost = 0, ItemIds = { "clothing_shirts_jersey" } },
	{ Id = "shirts_sports-jacket", Name = "Sports Jacket", Cost = 0, ItemIds = { "clothing_shirts_sports-jacket" } },
	{ Id = "pants_short-shorts", Name = "Short Shorts", Cost = 0, ItemIds = { "clothing_pants_short-shorts" } },
	{ Id = "accessories_knee-pads", Name = "Knee Pads", Cost = 833, ItemIds = { "costume_accessories_knee-pads" } },
	{
		Id = "accessories_rocket-boosters",
		Name = "Rocket Boosters",
		Cost = 825,
		ItemIds = { "costume_accessories_rocket-boosters" },
	},
	{
		Id = "accessories_shoulder-pads",
		Name = "Shoulder Pads",
		Cost = 818,
		ItemIds = { "costume_accessories_shoulder-pads" },
	},
	{
		Id = "accessories_shoulder-turrets",
		Name = "Shoulder Turrets",
		Cost = 7_575,
		ItemIds = { "costume_accessories_shoulder-turrets" },
	},
	{
		Id = "accessories_wrist-lasers",
		Name = "Wrist Lasers",
		Cost = 4_275,
		ItemIds = { "costume_accessories_wrist-lasers" },
	},
	{ Id = "emblems_box-emblem", Name = "Box Emblem", Cost = 818, ItemIds = { "costume_emblems_box-emblem" } },
	{
		Id = "emblems_lightning-emblem",
		Name = "Lightning Emblem",
		Cost = 7_275,
		ItemIds = { "costume_emblems_lightning-emblem" },
	},
	{
		Id = "emblems_octagon-emblem",
		Name = "Octagon Emblem",
		Cost = 788,
		ItemIds = { "costume_emblems_octagon-emblem" },
	},
	{
		Id = "emblems_shield-emblem",
		Name = "Shield Emblem",
		Cost = 3_713,
		ItemIds = { "costume_emblems_shield-emblem" },
	},
	{
		Id = "emblems_trispoke-emblem",
		Name = "Trispoke Emblem",
		Cost = 4_013,
		ItemIds = { "costume_emblems_trispoke-emblem" },
	},
	{ Id = "emblems_wing-emblem", Name = "Wing Emblem", Cost = 7_275, ItemIds = { "costume_emblems_wing-emblem" } },
	{ Id = "capes_jetpack", Name = "Jetpack", Cost = 810, ItemIds = { "costume_capes_jetpack" } },
	{ Id = "capes_wings", Name = "Wings", Cost = 3_600, ItemIds = { "costume_capes_wings" } },
	{ Id = "hair_animazinghair", Name = "Animazing hair", Cost = 773, ItemIds = { "cosmetics_hair_animazinghair" } },
	{ Id = "hair_bob-hair", Name = "Bob Hair", Cost = 765, ItemIds = { "cosmetics_hair_bob-hair" } },
	{ Id = "hair_crazy-hair", Name = "Crazy Hair", Cost = 818, ItemIds = { "cosmetics_hair_crazy-hair" } },
	{
		Id = "hair_lovely-locks-hair",
		Name = "Lovely Locks Hair",
		Cost = 675,
		ItemIds = { "cosmetics_hair_lovely-locks-hair" },
	},
	{
		Id = "hair_manga-hero-hair",
		Name = "Manga Hero Hair",
		Cost = 840,
		ItemIds = { "cosmetics_hair_manga-hero-hair" },
	},
	{ Id = "hair_mohawk-hair", Name = "Mohawk Hair", Cost = 788, ItemIds = { "cosmetics_hair_mohawk-hair" } },
	{
		Id = "hair_politician-hair",
		Name = "Politician Hair",
		Cost = 773,
		ItemIds = { "cosmetics_hair_politician-hair" },
	},
	{ Id = "hair_princeton-hair", Name = "Princeton Hair", Cost = 728, ItemIds = { "cosmetics_hair_princeton-hair" } },
	{ Id = "hair_roblohunk-hair", Name = "Roblohunk Hair", Cost = 795, ItemIds = { "cosmetics_hair_roblohunk-hair" } },
	{ Id = "hair_scene-hair", Name = "Scene Hair", Cost = 713, ItemIds = { "cosmetics_hair_scene-hair" } },
	{ Id = "hair_shaggy-hair", Name = "Shaggy Hair", Cost = 810, ItemIds = { "cosmetics_hair_shaggy-hair" } },
	{ Id = "hair_spiked-hair", Name = "Spiked Hair", Cost = 720, ItemIds = { "cosmetics_hair_spiked-hair" } },
	{ Id = "hair_straight-hair", Name = "Straight Hair", Cost = 698, ItemIds = { "cosmetics_hair_straight-hair" } },
	{ Id = "hair_stylish-hair", Name = "Stylish Hair", Cost = 750, ItemIds = { "cosmetics_hair_stylish-hair" } },
	{ Id = "hair_swoosh-hair", Name = "Swoosh Hair", Cost = 803, ItemIds = { "cosmetics_hair_swoosh-hair" } },
	{
		Id = "hair_ultraflash-hair",
		Name = "Ultraflash Hair",
		Cost = 720,
		ItemIds = { "cosmetics_hair_ultraflash-hair" },
	},
	{ Id = "hair_wavy-hair", Name = "Wavy Hair", Cost = 863, ItemIds = { "cosmetics_hair_wavy-hair" } },
	{ Id = "hats_backwards-cap", Name = "Backwards Cap", Cost = 855, ItemIds = { "clothing_hats_backwards-cap" } },
	{ Id = "hats_cap", Name = "Cap", Cost = 788, ItemIds = { "clothing_hats_cap" } },
	{ Id = "hats_headphones", Name = "Headphones", Cost = 758, ItemIds = { "clothing_hats_headphones" } },
	{ Id = "hats_side-cap", Name = "Side Cap", Cost = 698, ItemIds = { "clothing_hats_side-cap" } },
	{
		Id = "glasses_hipster-glasses",
		Name = "Hipster Glasses",
		Cost = 795,
		ItemIds = { "clothing_glasses_hipster-glasses" },
	},
	{ Id = "glasses_shades", Name = "Shades", Cost = 645, ItemIds = { "clothing_glasses_shades" } },
	{ Id = "eyes_brave", Name = "Brave Eyes", Cost = 3_225, ItemIds = { "cosmetics_eyes_brave" } },
	{ Id = "eyes_normal", Name = "Normal Eyes", Cost = 735, ItemIds = { "cosmetics_eyes_normal" } },
	{ Id = "eyes_scared", Name = "Scared Eyes", Cost = 668, ItemIds = { "cosmetics_eyes_scared" } },
	{ Id = "eyes_worried", Name = "Worried Eyes", Cost = 653, ItemIds = { "cosmetics_eyes_worried" } },
	{ Id = "mouths_monster-smile", Name = "Monster Smile", Cost = 720, ItemIds = { "cosmetics_mouth_monster-smile" } },
	{ Id = "attacks_bo-staff", Name = "Bo Staff", Cost = 653, PowerId = "basic-melee_bo-staff" },
	{ Id = "attacks_sword", Name = "Sword", Cost = 720, PowerId = "basic-melee_sword" },
	{ Id = "attacks_hammer", Name = "Hammer", Cost = 825, PowerId = "basic-melee_hammer" },
	{ Id = "attacks_fire-ray", Name = "Fire Ray", Cost = 3_263, PowerId = "ranged_fire-ray" },
	{ Id = "attacks_freeze-ray", Name = "Freeze Ray", Cost = 3_300, PowerId = "ranged_freeze-ray" },
	{ Id = "attacks_lightning", Name = "Lightning", Cost = 7_575, PowerId = "ranged_lightning" },
	{ Id = "effects_mind-reading", Name = "Mind Reading", Cost = 3_338, PowerId = "special_mind-reading" },
	{ Id = "effects_teleport", Name = "Teleport", Cost = 3_525, PowerId = "transportation_teleport" },
	{ Id = "effects_x-ray-vision", Name = "X-Ray Vision", Cost = 4_050, PowerId = "special_x-ray-vision" },
	{ Id = "effects_force-field", Name = "Force Field", Cost = 7_725, PowerId = "special_force-shield" },
	{ Id = "effects_invisibility", Name = "Invisibility", Cost = 31_500, PowerId = "special_invisibility" },
}
local CATALOGUE: AccessCatalogue = {
	PriceAdjust = PRICE_ADJUST,
	Currency = "Credits",
	Listings = LISTINGS,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
