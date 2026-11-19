--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Balances = EconomyType.Balances
type ProductCatalogue = EconomyType.ProductCatalogue
type ProductDefinition = EconomyType.ProductDefinition
-- Constants
-- ids are from the old place, they stay what the players of it paid for
local LEGACY_DEVELOPER_PRODUCT_IDS = table.freeze({
	CREDITS_50 = 25402120,
	CREDITS_300 = 25402128,
	CREDITS_650 = 25402159,
	CREDITS_1400 = 25402252,
	CREDITS_7500 = 25402273,
	CREDITS_16000 = 25402286,
})
-- from before there were game passes: each is an asset a player owns. the suits were sold under two more
local LEGACY_PASS_ASSET_IDS = table.freeze({
	MASKS = 254853829,
	HAIR = 253962381,
	FACES = 255681011,
	POWERS = 254032943,
	SUITS = 279089669,
	SUITS_OLD_1 = 243650331,
	SUITS_OLD_2 = 243923177,
})
-- every currency goes by a name, nothing here hands out or shows a gem
local CURRENCY_NAMES: { [PseudoEnum.Currency]: string } = table.freeze({
	Credits = "C$",
	Gems = "Gems",
})
-- the five rows of the old save list, no pass adds to them
local DEFAULT_CHARACTER_SLOT_COUNT = 5
local EXTRA_CHARACTER_SLOT_COUNT = 0
local STARTING_BALANCES: Balances = table.freeze({
	Credits = 0,
	Gems = 0,
})
-- the price text is what a card shows until the live price is known, the old shop spelt both out: "5 R$ = 50 C$"
local DEFINITIONS: { ProductDefinition } = {
	{
		Id = "credits_50",
		Tab = "Credits",
		Name = "50 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 50 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_50,
		LegacyPriceText = "5 R$",
	},
	{
		Id = "credits_300",
		Tab = "Credits",
		Name = "300 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 300 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_300,
		LegacyPriceText = "25 R$",
	},
	{
		Id = "credits_650",
		Tab = "Credits",
		Name = "650 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 650 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_650,
		LegacyPriceText = "50 R$",
	},
	{
		Id = "credits_1400",
		Tab = "Credits",
		Name = "1,400 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 1_400 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_1400,
		LegacyPriceText = "100 R$",
	},
	{
		Id = "credits_7500",
		Tab = "Credits",
		Name = "7,500 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 7_500 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_7500,
		LegacyPriceText = "500 R$",
	},
	{
		Id = "credits_16000",
		Tab = "Credits",
		Name = "16,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 16_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_16000,
		LegacyPriceText = "1000 R$",
	},
}
-- the passes aren't sold yet + nobody is asked whether they own one: until what they open is held back from
-- anybody, everything is everybody's. the old place never wrote down what a pass cost
local UPCOMING: { ProductDefinition } = {
	{
		Id = "gamepasses_masks",
		Tab = "Gamepasses",
		Name = "Masks",
		Grant = { Type = "Entitlement", Key = "PremiumMasks" },
		LegacyId = LEGACY_PASS_ASSET_IDS.MASKS,
		LegacyPriceText = "",
		IsAsset = true,
	},
	{
		Id = "gamepasses_hair",
		Tab = "Gamepasses",
		Name = "Hair",
		Grant = { Type = "Entitlement", Key = "PremiumHair" },
		LegacyId = LEGACY_PASS_ASSET_IDS.HAIR,
		LegacyPriceText = "",
		IsAsset = true,
	},
	{
		Id = "gamepasses_faces",
		Tab = "Gamepasses",
		Name = "Faces",
		Grant = { Type = "Entitlement", Key = "PremiumFaces" },
		LegacyId = LEGACY_PASS_ASSET_IDS.FACES,
		LegacyPriceText = "",
		IsAsset = true,
	},
	-- one pass for the powers of all three slots
	{
		Id = "gamepasses_powers",
		Tab = "Gamepasses",
		Name = "Abilities",
		Grant = { Type = "Entitlement", Key = "PremiumPowers" },
		LegacyId = LEGACY_PASS_ASSET_IDS.POWERS,
		LegacyPriceText = "",
		IsAsset = true,
	},
	{
		Id = "gamepasses_suits",
		Tab = "Gamepasses",
		Name = "Suits",
		Grant = { Type = "Entitlement", Key = "PremiumSuits" },
		LegacyId = LEGACY_PASS_ASSET_IDS.SUITS,
		OtherLegacyIds = { LEGACY_PASS_ASSET_IDS.SUITS_OLD_1, LEGACY_PASS_ASSET_IDS.SUITS_OLD_2 },
		LegacyPriceText = "",
		IsAsset = true,
	},
}
-- nobody is handed anything for coming back, so there's no daily reward
local CATALOGUE: ProductCatalogue = {
	Definitions = DEFINITIONS,
	Upcoming = UPCOMING,
	CurrencyNames = CURRENCY_NAMES,
	DefaultCharacterSlotCount = DEFAULT_CHARACTER_SLOT_COUNT,
	ExtraCharacterSlotCount = EXTRA_CHARACTER_SLOT_COUNT,
	StartingBalances = STARTING_BALANCES,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
