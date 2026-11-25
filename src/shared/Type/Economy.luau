--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Types
local Types = {}

export type Currency = PseudoEnum.Currency
Types.Currency = Type.literal(table.unpack(PseudoEnum.getEnumItems("Currency")))

export type Balance = number
Types.Balance = Type.intersection(Type.integer, Type.numberMin(0))

export type Balances = {
	Credits: Balance,
	Gems: Balance,
	[Currency]: Balance,
}
Types.Balances = Type.intersection(
	Type.interface({
		Credits = Types.Balance,
		Gems = Types.Balance,
	}),
	Type.map(Types.Currency, Types.Balance)
)

export type ShopTab = "Credits" | "Gems" | "Gamepasses"
Types.ShopTab = Type.literal("Credits", "Gems", "Gamepasses")

-- of every game. which of them a game hands out is up to the passes it sells
export type EntitlementKey =
	"FifthPower"
	| "ExtraCharacterSlots"
	| "MultiHair"
	| "ExtraPowers"
	| "AdvancedRoleplay"
	| "PremiumMasks"
	| "PremiumHair"
	| "PremiumFaces"
	| "PremiumPowers"
	| "PremiumSuits"
Types.EntitlementKey = Type.literal(
	"FifthPower",
	"ExtraCharacterSlots",
	"MultiHair",
	"ExtraPowers",
	"AdvancedRoleplay",
	"PremiumMasks",
	"PremiumHair",
	"PremiumFaces",
	"PremiumPowers",
	"PremiumSuits"
)

export type ProductGrant =
	{
		Type: "Currency",
		Currency: Currency,
		Amount: number,
	}
	| {
		Type: "Entitlement",
		Key: EntitlementKey,
	}
Types.ProductGrant = Type.union(
	Type.strictInterface({
		Type = Type.literal("Currency"),
		Currency = Types.Currency,
		Amount = Type.intersection(Type.integer, Type.numberPositive),
	}),
	Type.strictInterface({
		Type = Type.literal("Entitlement"),
		Key = Types.EntitlementKey,
	})
)

-- a product that grants an entitlement is a gamepass, every other one is a developer product. a pass from before
-- there were game passes is an asset a player owns, which the platform is asked about another way
export type ProductDefinition = {
	Id: string,
	Tab: ShopTab,
	Name: string,
	Grant: ProductGrant,
	LegacyId: number,
	OtherLegacyIds: { number }?, -- what it was sold under before, owning one of those is owning it
	LegacyPriceText: string,
	IsAsset: boolean?,
}
Types.ProductDefinition = Type.strictInterface({
	Id = Type.string,
	Tab = Types.ShopTab,
	Name = Type.string,
	Grant = Types.ProductGrant,
	LegacyId = Type.integer,
	OtherLegacyIds = Type.optional(Type.array(Type.integer)),
	LegacyPriceText = Type.string,
	IsAsset = Type.optional(Type.boolean),
})

-- what a player is handed for coming back, the interval is the seconds between two of them
export type DailyReward = {
	Currency: Currency,
	Amount: number,
	Interval: number,
}
Types.DailyReward = Type.strictInterface({
	Currency = Types.Currency,
	Amount = Type.intersection(Type.integer, Type.numberPositive),
	Interval = Type.numberPositive,
})

-- what a game sells + what it gives away: its products, what its currencies go by, how many characters a player keeps
-- without the pass + how many more with it, what a new player starts on. a game that hands nothing out for coming back
-- has no daily reward
export type ProductCatalogue = {
	Definitions: { ProductDefinition },
	Upcoming: { ProductDefinition }?, -- the ones that aren't sold yet, nobody is asked whether they own one
	CurrencyNames: { [Currency]: string },
	DefaultCharacterSlotCount: number,
	ExtraCharacterSlotCount: number,
	StartingBalances: Balances,
	DailyReward: DailyReward?,
}
Types.ProductCatalogue = Type.strictInterface({
	Definitions = Type.array(Types.ProductDefinition),
	Upcoming = Type.optional(Type.array(Types.ProductDefinition)),
	CurrencyNames = Type.map(Types.Currency, Type.string),
	DefaultCharacterSlotCount = Type.intersection(Type.integer, Type.numberPositive),
	ExtraCharacterSlotCount = Type.intersection(Type.integer, Type.numberMin(0)),
	StartingBalances = Types.Balances,
	DailyReward = Type.optional(Types.DailyReward),
})

-- what opens something that isn't sold for a currency: a pass of the game, or having been seen in its group
export type Lock =
	{
		Type: "Entitlement",
		Key: EntitlementKey,
	}
	| {
		Type: "GroupPerk",
	}
Types.Lock = Type.union(
	Type.strictInterface({
		Type = Type.literal("Entitlement"),
		Key = Types.EntitlementKey,
	}),
	Type.strictInterface({
		Type = Type.literal("GroupPerk"),
	})
)

-- what stands between a player + an item or a power: nothing, a price that's paid once, or a lock
export type Access = {
	Type: "Free",
} | {
	Type: "Price",
	Currency: Currency,
	Amount: number,
} | Lock
Types.Access = Type.union(
	Type.strictInterface({
		Type = Type.literal("Free"),
	}),
	Type.strictInterface({
		Type = Type.literal("Price"),
		Currency = Types.Currency,
		Amount = Types.Balance,
	}),
	Types.Lock
)

-- something a game holds back from whoever didn't get it yet, handed over as a whole: the items of one entry of its
-- catalogue (a suit is one for each limb) or one power. it's sold at its cost, which the game adjusts as one, or
-- it's behind a lock
export type Listing = {
	Id: string,
	Name: string,
	ItemIds: { string }?,
	PowerId: string?,
	Cost: number?, -- as the old game stored it, before its adjustment
	Lock: Lock?,
}
do -- Types.Listing
	local isShape = Type.strictInterface({
		Id = Type.string,
		Name = Type.string,
		ItemIds = Type.optional(Type.array(Type.string)),
		PowerId = Type.optional(Type.string),
		Cost = Type.optional(Types.Balance),
		Lock = Type.optional(Types.Lock),
	})
	-- it hands over items or a power, never both, + it's held back one way
	local function isWhole(value: Listing): (boolean, string?)
		local itemIds = value.ItemIds
		if (itemIds ~= nil) == (value.PowerId ~= nil) or (itemIds and #itemIds == 0) then
			return false, `"{value.Id}" is to hand over the items of an entry or one power`
		end
		if (value.Cost ~= nil) == (value.Lock ~= nil) then
			return false, `"{value.Id}" is to have a cost or a lock`
		end
		return true
	end
	Types.Listing = Type.intersection(isShape, isWhole)
end

-- everything a game holds back. a price is the cost times the adjustment, rounded up to a whole hundred
export type AccessCatalogue = {
	PriceAdjust: number,
	Currency: Currency,
	Listings: { Listing },
}
Types.AccessCatalogue = Type.strictInterface({
	PriceAdjust = Type.numberPositive,
	Currency = Types.Currency,
	Listings = Type.array(Types.Listing),
})

-- what a player has of what their game holds back: what they bought, by the ids that were handed over, + what opens
-- its locks. a game only fills in what it has listings for
export type Owned = {
	ItemIds: { string },
	PowerIds: { string },
	Entitlements: { EntitlementKey }?,
	HasGroupPerk: boolean?,
}
Types.Owned = Type.strictInterface({
	ItemIds = Type.array(Type.string),
	PowerIds = Type.array(Type.string),
	Entitlements = Type.optional(Type.array(Types.EntitlementKey)),
	HasGroupPerk = Type.optional(Type.boolean),
})

-- what the engine hands the server once a developer product is paid for, only the fields that are read
export type Receipt = {
	PurchaseId: string,
	PlayerId: number,
	ProductId: number,
}
Types.Receipt = Type.interface({
	PurchaseId = Type.string,
	PlayerId = Type.integer,
	ProductId = Type.integer,
})

return Types
