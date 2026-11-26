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
local ALLOWANCE = if CATALOGUE.Allowance
	then table.freeze({
		CURRENCY = CATALOGUE.Allowance.Currency,
		AMOUNT = CATALOGUE.Allowance.Amount,
		INTERVAL = CATALOGUE.Allowance.Interval,
	})
	else nil
-- nil in a game that hands nothing out for being in a group
local GROUP_ID = CATALOGUE.GroupId
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
Module.ALLOWANCE = ALLOWANCE
Module.GROUP_ID = GROUP_ID

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

-- how a pass is asked about + sold: by an id, + whether that's the asset it was before there were game passes. one
-- of those that has an id of today goes by it, as the game pass it is now
Module.getPassPrompt = function(definition: ProductDefinition): (number, boolean)
	if definition.PassId then
		return definition.PassId, false
	end
	return definition.LegacyId, definition.IsAsset == true
end

-- the pass a prompt of the engine was for, by what it was prompted as
Module.getFromPassPrompt = function(id: number, isAsset: boolean): Result<ProductDefinition, string>
	for _, definition in DEFINITIONS do
		if Module.getIfGamePass(definition) then
			local promptId, isPromptAsset = Module.getPassPrompt(definition)
			if promptId == id and isPromptAsset == isAsset then
				return Result.ok(definition)
			end
		end
	end
	return Result.err(`no {if isAsset then "asset" else "game"} pass {id}`)
end

-- the pass that hands an entitlement out
Module.getFromEntitlement = function(key: EntitlementKey): Result<ProductDefinition, string>
	for _, definition in DEFINITIONS do
		local grant = definition.Grant
		if grant.Type == "Entitlement" and grant.Key == key then
			return Result.ok(definition)
		end
	end
	return Result.err(`no pass hands out "{key}"`)
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
