--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
export type ProductDefinition = EconomyType.ProductDefinition
export type ShopTab = EconomyType.ShopTab
export type EntitlementKey = EconomyType.EntitlementKey
type ProductCatalogue = EconomyType.ProductCatalogue
-- Constants
-- what's sold, what the currencies go by + what a player starts on is the game's own, the products of another game are
-- never required
local CATALOGUE: ProductCatalogue = GameDefinition.pick({
	shl1 = function(): ProductCatalogue
		return require("@self/SHL1")
	end,
	shl2 = function(): ProductCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): ProductCatalogue
		return require("@self/SHL3")
	end,
})
assert(EconomyType.ProductCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local DEFINITIONS = CATALOGUE.Definitions
local UPCOMING: { ProductDefinition } = CATALOGUE.Upcoming or table.freeze({})
local CURRENCY_NAMES = CATALOGUE.CurrencyNames
local DEFAULT_CHARACTER_SLOT_COUNT = CATALOGUE.DefaultCharacterSlotCount
local EXTRA_CHARACTER_SLOT_COUNT = CATALOGUE.ExtraCharacterSlotCount
local STARTING_BALANCES = CATALOGUE.StartingBalances
-- nil in a game that has none
local DAILY_REWARD = if CATALOGUE.DailyReward
	then table.freeze({
		CURRENCY = CATALOGUE.DailyReward.Currency,
		AMOUNT = CATALOGUE.DailyReward.Amount,
		INTERVAL = CATALOGUE.DailyReward.Interval,
	})
	else nil
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- every currency is drawn by its name somewhere, the checker doesn't see one that's left out
for _, currency: PseudoEnum.Currency in PseudoEnum.getEnumItems("Currency") do
	assert(CURRENCY_NAMES[currency] ~= nil, `the "{currency}" currency has no name`)
end

do
	-- an upcoming product is held to what every row is, so all it takes once it's sold is moving the row. until then
	-- no id of theirs is answered for: it isn't listed, prompted or asked about
	local ids: { [string]: true } = {}
	for _, definition in DEFINITIONS do
		ids[definition.Id] = true
	end
	for _, definition in UPCOMING do
		assert(not ids[definition.Id], `duplicate product id "{definition.Id}"`)
		ids[definition.Id] = true
	end
end

Module.STARTING_BALANCES = STARTING_BALANCES
Module.DAILY_REWARD = DAILY_REWARD

Module.getCurrencyName = function(currency: PseudoEnum.Currency): string
	return CURRENCY_NAMES[currency]
end

Module.getPowerLimit = function(entitlements: { EntitlementKey }): number
	-- no pass raises the limit of a game that names none
	local passEntitlement = PowerDefinition.PASS_ENTITLEMENT
	return if passEntitlement ~= nil and table.find(entitlements, passEntitlement)
		then PowerDefinition.PASS_LIMIT
		else PowerDefinition.DEFAULT_LIMIT
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

-- what the game's passes hand out, in the order they're sold in
Module.listEntitlements = function(): { EntitlementKey }
	local out: { EntitlementKey } = {}
	for _, definition in DEFINITIONS do
		local grant = definition.Grant
		if grant.Type == "Entitlement" and table.find(out, grant.Key) == nil then
			table.insert(out, grant.Key)
		end
	end
	table.freeze(out)
	return out
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
