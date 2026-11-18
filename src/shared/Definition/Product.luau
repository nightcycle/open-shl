--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
export type ProductDefinition = EconomyType.ProductDefinition
export type ShopTab = EconomyType.ShopTab
export type EntitlementKey = EconomyType.EntitlementKey
type Balances = EconomyType.Balances
-- Constants
-- ids are from the old place, swap once the products are re-created
local LEGACY_DEVELOPER_PRODUCT_IDS = table.freeze({
	CREDITS_1000 = 84563220,
	CREDITS_5000 = 84563236,
	CREDITS_10000 = 84563255,
	CREDITS_50000 = 84563275,
	CREDITS_100000 = 84563332,
	CREDITS_500000 = 84563358,
	GEMS_50 = 84562589,
	GEMS_250 = 84562607,
	GEMS_500 = 84562627,
	GEMS_2500 = 84562829,
	GEMS_5000 = 84562842,
	GEMS_25000 = 84562869,
})
local LEGACY_GAMEPASS_IDS = table.freeze({
	FIFTH_POWER = 2777959,
	EXTRA_CHARACTER_SLOTS = 2777953,
	MULTI_HAIR = 8699266,
})
local CURRENCY_NAMES: { [PseudoEnum.Currency]: string } = table.freeze({
	Credits = "Super Credits",
	Gems = "Power Gems",
})
local DEFAULT_CHARACTER_SLOT_COUNT = 10
local EXTRA_CHARACTER_SLOT_COUNT = 10
local STARTING_BALANCES: Balances = table.freeze({
	Credits = 500,
	Gems = 0,
})
local DAILY_REWARD = table.freeze({
	CURRENCY = PseudoEnum.Currency.Gems,
	AMOUNT = 5,
	INTERVAL = 24 * 60 * 60,
})
-- the price text is what a card shows until the live price is known
local DEFINITIONS: { ProductDefinition } = {
	{
		Id = "credits_1000",
		Tab = "Credits",
		Name = "Buy 1,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 1_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_1000,
		LegacyPriceText = "20 R$",
	},
	{
		Id = "credits_5000",
		Tab = "Credits",
		Name = "Buy 5,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 5_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_5000,
		LegacyPriceText = "90 R$",
	},
	{
		Id = "credits_10000",
		Tab = "Credits",
		Name = "Buy 10,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 10_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_10000,
		LegacyPriceText = "160 R$",
	},
	{
		Id = "credits_50000",
		Tab = "Credits",
		Name = "Buy 50,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 50_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_50000,
		LegacyPriceText = "700 R$",
	},
	{
		Id = "credits_100000",
		Tab = "Credits",
		Name = "Buy 100,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 100_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_100000,
		LegacyPriceText = "1,300 R$",
	},
	{
		Id = "credits_500000",
		Tab = "Credits",
		Name = "Buy 500,000 C$",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Credits, Amount = 500_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.CREDITS_500000,
		LegacyPriceText = "6,000 R$",
	},
	{
		Id = "gems_50",
		Tab = "Gems",
		Name = "Buy 50 Gems",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Gems, Amount = 50 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.GEMS_50,
		LegacyPriceText = "20 R$",
	},
	{
		Id = "gems_250",
		Tab = "Gems",
		Name = "Buy 250 Gems",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Gems, Amount = 250 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.GEMS_250,
		LegacyPriceText = "90 R$",
	},
	{
		Id = "gems_500",
		Tab = "Gems",
		Name = "Buy 500 Gems",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Gems, Amount = 500 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.GEMS_500,
		LegacyPriceText = "160 R$",
	},
	{
		Id = "gems_2500",
		Tab = "Gems",
		Name = "Buy 2,500 Gems",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Gems, Amount = 2_500 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.GEMS_2500,
		LegacyPriceText = "700 R$",
	},
	{
		Id = "gems_5000",
		Tab = "Gems",
		Name = "Buy 5,000 Gems",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Gems, Amount = 5_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.GEMS_5000,
		LegacyPriceText = "1,300 R$",
	},
	{
		Id = "gems_25000",
		Tab = "Gems",
		Name = "Buy 25,000 Gems",
		Grant = { Type = "Currency", Currency = PseudoEnum.Currency.Gems, Amount = 25_000 },
		LegacyId = LEGACY_DEVELOPER_PRODUCT_IDS.GEMS_25000,
		LegacyPriceText = "6,000 R$",
	},
	{
		Id = "gamepasses_fifth-power",
		Tab = "Gamepasses",
		Name = "Have a 5th Power",
		Grant = { Type = "Entitlement", Key = "FifthPower" },
		LegacyId = LEGACY_GAMEPASS_IDS.FIFTH_POWER,
		LegacyPriceText = "350 R$",
	},
	{
		Id = "gamepasses_extra-character-slots",
		Tab = "Gamepasses",
		Name = "10 Extra Suit Slots",
		Grant = { Type = "Entitlement", Key = "ExtraCharacterSlots" },
		LegacyId = LEGACY_GAMEPASS_IDS.EXTRA_CHARACTER_SLOTS,
		LegacyPriceText = "700 R$",
	},
	{
		Id = "gamepasses_multi-hair",
		Tab = "Gamepasses",
		Name = "Multi-Hairs!",
		Grant = { Type = "Entitlement", Key = "MultiHair" },
		LegacyId = LEGACY_GAMEPASS_IDS.MULTI_HAIR,
		LegacyPriceText = "300 R$",
	},
}
TableUtil.deepFreeze(DEFINITIONS)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.STARTING_BALANCES = STARTING_BALANCES
Module.DAILY_REWARD = DAILY_REWARD

Module.getCurrencyName = function(currency: PseudoEnum.Currency): string
	return CURRENCY_NAMES[currency]
end

Module.getPowerLimit = function(entitlements: { EntitlementKey }): number
	return if table.find(entitlements, "FifthPower") then PowerDefinition.PASS_LIMIT else PowerDefinition.DEFAULT_LIMIT
end

Module.getCharacterSlotCount = function(entitlements: { EntitlementKey }): number
	if table.find(entitlements, "ExtraCharacterSlots") then
		return DEFAULT_CHARACTER_SLOT_COUNT + EXTRA_CHARACTER_SLOT_COUNT
	end
	return DEFAULT_CHARACTER_SLOT_COUNT
end

Module.getIfGamePass = function(definition: ProductDefinition): boolean
	return definition.Grant.Type == "Entitlement"
end

Module.get = function(id: string): Result<ProductDefinition, string>
	for _, definition in DEFINITIONS do
		if definition.Id == id then
			return Result.ok(definition)
		end
	end
	return Result.err(`no product "{id}"`)
end

-- a game pass + a developer product can carry the same number, so which of the two is meant comes with it
Module.getFromLegacyId = function(legacyId: number, isGamePass: boolean): Result<ProductDefinition, string>
	for _, definition in DEFINITIONS do
		if definition.LegacyId == legacyId and Module.getIfGamePass(definition) == isGamePass then
			return Result.ok(definition)
		end
	end
	return Result.err(`no {if isGamePass then "game pass" else "developer product"} {legacyId}`)
end

Module.list = function(tab: ShopTab?): { ProductDefinition }
	local out = {}
	for _, definition in DEFINITIONS do
		if tab ~= nil then
			if tab ~= definition.Tab then
				continue
			end
		end
		table.insert(out, definition)
	end
	table.freeze(out)
	return out
end

return Module
