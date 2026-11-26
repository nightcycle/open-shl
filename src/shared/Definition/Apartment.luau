--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Scale = AppearanceType.Scale
type TextureGroupKey = AppearanceType.TextureGroupKey
-- one kind of flat the salesman has, a dearer one is a larger room
export type Row = {
	Tier: number, -- what a save holds of it, 1 for the cheapest
	Id: string, -- what the old place kept of it, there for a save of it that's brought over
	Name: string,
	Price: number,
	Currency: PseudoEnum.Currency,
	ModelName: string, -- the room of the library a client builds it from
}
-- what the salesman has on, each piece in the colors his record of the old place gave it
export type Look = {
	SkinColor: Color3,
	HairColor: Color3,
	Scale: Scale,
	Items: { { DefinitionId: string, Colors: { [TextureGroupKey]: Color3 } } },
}
-- Constants
local CURRENCY: PseudoEnum.Currency = PseudoEnum.Currency.Credits
local JEANS_COLOR = Color3.new(0.0667, 0.0667, 0.0667)
local SALESMAN_LOOK: Look = {
	SkinColor = Color3.new(1, 0.804, 0.74),
	HairColor = Color3.new(0.337, 0.259, 0.212),
	Scale = { Height = 1, Width = 0.875 },
	Items = {
		{
			DefinitionId = "clothing_shirts_suit-coat",
			Colors = { Primary = Color3.new(0, 0, 0), Secondary = Color3.new(0.652, 0, 0.0946) },
		},
		{ DefinitionId = "clothing_pants_jeans", Colors = { Primary = JEANS_COLOR, Secondary = JEANS_COLOR } },
		{ DefinitionId = "cosmetics_hair_spiked-hair", Colors = {} },
		{ DefinitionId = "cosmetics_eyes_brave", Colors = {} },
		{ DefinitionId = "cosmetics_mouth_brave", Colors = {} },
	},
}
TableUtil.deepFreeze(SALESMAN_LOOK)
-- Variables
-- References
-- Private Functions
local function newRow(tier: number, id: string, name: string, price: number, modelName: string): Row
	return { Tier = tier, Id = id, Name = name, Price = price, Currency = CURRENCY, ModelName = modelName }
end
-- in the order he lists them. the old place never ran these through the price adjustment of its catalogue
local ROWS: { Row } = {
	newRow(1, "LowClass", "Lower Class", 250, "low-class"),
	newRow(2, "MiddleClass", "Middle Class", 1_250, "middle-class"),
	newRow(3, "UpperClass", "Upper Class", 4_250, "upper-class"),
	newRow(4, "LuxuryClass", "Luxury Class", 10_000, "luxury-class"),
}
TableUtil.deepFreeze(ROWS)
-- Class
-- the flats of superhero life 3: four kinds of room in one tower, sold by the salesman in its lobby
local Module = {}

-- the only thing a client says of a purchase: which kind, never a name or a price
Module.Tier =
	Type.intersection(Type.integer, Type.numberConstrained(1, #ROWS)) :: (value: unknown) -> (boolean, string?)

Module.SALESMAN_NAME = "Apartment Guy"
Module.SALESMAN_LOOK = SALESMAN_LOOK
-- studs from him a talk is had within, as far as the engine's own dialog of the old place reached
Module.CONVERSATION_DISTANCE = 25
Module.TITLE = "BELMONT SQUARE"
Module.PROMPT = "Welcome to Belmont Square, would you like to buy a new condo?"
Module.RESPONSE = "Excellent choice! Enter the elevator to your left to find your apartment!"
-- what whoever owns a flat is told while every one of the tower is lived in
Module.FULL_ALERT = "Every apartment is taken right now"

Module.list = function(): { Row }
	return ROWS
end

-- a save holds 0 until a flat is bought, that's none of them
Module.get = function(tier: number): Result<Row, string>
	local row = ROWS[tier]
	if not row then
		return Result.err(`no flat of tier {tier}`)
	end
	return Result.ok(row)
end

-- the line of the salesman for it, the way the old place wrote its prices
Module.getRowText = function(row: Row): string
	return `{row.Name} - ${row.Price}`
end

return table.freeze(Module)
