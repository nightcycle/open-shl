--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Allowance = EconomyType.Allowance
type Balances = EconomyType.Balances
type ProductCatalogue = EconomyType.ProductCatalogue
type ProductDefinition = EconomyType.ProductDefinition
-- Constants
-- ids are from the old place, they stay what the players of it paid for
local LEGACY_DEVELOPER_PRODUCT_IDS = table.freeze({
	CREDITS_500 = 347506191,
	CREDITS_2500 = 347506438,
	CREDITS_5000 = 347506860,
	CREDITS_10000 = 347507217,
	CREDITS_25000 = 347508224,
	CREDITS_50000 = 347508795,
})
local LEGACY_GAMEPASS_IDS = table.freeze({
	ADVANCED_ROLEPLAY = 5365048,
	EXTRA_CHARACTER_SLOTS = 5369645,
	EXTRA_POWERS = 5391229,
})
-- every currency goes by a name, nothing here hands out or shows a gem
local CURRENCY_NAMES: { [PseudoEnum.Currency]: string } = table.freeze({
	Credits = "Credits",
	Gems = "Gems",
})
local DEFAULT_CHARACTER_SLOT_COUNT = 5
local EXTRA_CHARACTER_SLOT_COUNT = 5
local STARTING_BALANCES: Balances = table.freeze({
	Credits = 1_000,
	Gems = 0,
})
-- everybody who's in a server is handed this every five minutes, whatever they're at: its old place asked about
-- nothing. 600 an hour, its best flat is 10,000
local ALLOWANCE: Allowance = table.freeze({
	Currency = PseudoEnum.Currency.Credits,
	Amount = 50,
	Interval = 300,
})
-- the price text is what a card shows until the live price is known, the old place never wrote down what a pass cost
local DEFINITIONS: { ProductDefinition } = {
	{
		Id = "credits_500",
		Tab = "Credits",
		Name = "500 credits",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 500 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_500,
		LegacyPriceText = "50 R$",
	},
	{
		Id = "credits_2500",
		Tab = "Credits",
		Name = "2,500 credits",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 2_500 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_2500,
		LegacyPriceText = "200 R$",
	},
	{
		Id = "credits_5000",
		Tab = "Credits",
		Name = "5,000 credits",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 5_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_5000,
		LegacyPriceText = "350 R$",
	},
	{
		Id = "credits_10000",
		Tab = "Credits",
		Name = "10,000 credits",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 10_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_10000,
		LegacyPriceText = "500 R$",
	},
	{
		Id = "credits_25000",
		Tab = "Credits",
		Name = "25,000 credits",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 25_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_25000,
		LegacyPriceText = "1300 R$",
	},
	{
		Id = "credits_50000",
		Tab = "Credits",
		Name = "50,000 credits",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 50_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_50000,
		LegacyPriceText = "2400 R$",
	},
	{
		Id = "gamepasses_extra-character-slots",
		Tab = "Gamepasses",
		Name = "Double Save Slots",
		Grant = { Type = "Entitlement", Key = "ExtraCharacterSlots" },
		LegacyId = LEGACY_GAMEPASS_IDS.EXTRA_CHARACTER_SLOTS,
		LegacyPriceText = "",
	},
	{
		Id = "gamepasses_extra-powers",
		Tab = "Gamepasses",
		Name = "Extra Power Slots",
		Grant = { Type = "Entitlement", Key = "ExtraPowers" },
		LegacyId = LEGACY_GAMEPASS_IDS.EXTRA_POWERS,
		LegacyPriceText = "",
	},
	{
		Id = "gamepasses_advanced-roleplay",
		Tab = "Gamepasses",
		Name = "Adv. Roleplay Tools",
		Grant = { Type = "Entitlement", Key = "AdvancedRoleplay" },
		LegacyId = LEGACY_GAMEPASS_IDS.ADVANCED_ROLEPLAY,
		LegacyPriceText = "",
	},
}
-- nobody is handed anything for coming back, so there's no daily reward
local CATALOGUE: ProductCatalogue = {
	Definitions = DEFINITIONS,
	CurrencyNames = CURRENCY_NAMES,
	DefaultCharacterSlotCount = DEFAULT_CHARACTER_SLOT_COUNT,
	ExtraCharacterSlotCount = EXTRA_CHARACTER_SLOT_COUNT,
	StartingBalances = STARTING_BALANCES,
	Allowance = ALLOWANCE,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
