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

export type ShopTab = "Credits" | "Gems" | "Artifacts" | "Gamepasses"
Types.ShopTab = Type.literal("Credits", "Gems", "Artifacts", "Gamepasses")

export type EntitlementKey = "FifthPower" | "ExtraCharacterSlots" | "MultiHair"
Types.EntitlementKey = Type.literal("FifthPower", "ExtraCharacterSlots", "MultiHair")

export type ProductGrant =
	{
		Type: "Currency",
		Currency: Currency,
		Amount: number,
	}
	| {
		Type: "Artifact",
		Rarity: PseudoEnum.Rarity,
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
		Type = Type.literal("Artifact"),
		Rarity = Type.literal(table.unpack(PseudoEnum.getEnumItems("Rarity"))),
	}),
	Type.strictInterface({
		Type = Type.literal("Entitlement"),
		Key = Types.EntitlementKey,
	})
)

-- a product that grants an entitlement is a gamepass, every other one is a developer product
export type ProductDefinition = {
	Id: string,
	Tab: ShopTab,
	Name: string,
	Grant: ProductGrant,
	LegacyId: number,
	LegacyPriceText: string,
}
Types.ProductDefinition = Type.strictInterface({
	Id = Type.string,
	Tab = Types.ShopTab,
	Name = Type.string,
	Grant = Types.ProductGrant,
	LegacyId = Type.integer,
	LegacyPriceText = Type.string,
})

return Types
