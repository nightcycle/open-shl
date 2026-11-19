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
