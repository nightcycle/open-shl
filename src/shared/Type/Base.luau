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

export type FurnitureCategory = "Vehicles" | "Workshop" | "Armory" | "Research" | "Training" | "Artifacts" | "Conference"
Types.FurnitureCategory =
	Type.literal("Vehicles", "Workshop", "Armory", "Research", "Training", "Artifacts", "Conference")

export type FurnitureDefinition = {
	Id: string, -- the name of the model in the decoration library
	Name: string,
	Category: FurnitureCategory,
	Price: number,
	Currency: PseudoEnum.Currency,
	IsFunctional: boolean,
	LegacyThumbnailId: number,
}
Types.FurnitureDefinition = Type.strictInterface({
	Id = Type.string,
	Name = Type.string,
	Category = Types.FurnitureCategory,
	Price = Type.intersection(Type.integer, Type.numberMin(0)),
	Currency = Type.literal(table.unpack(PseudoEnum.getEnumItems("Currency"))),
	IsFunctional = Type.boolean,
	LegacyThumbnailId = Type.integer,
})

export type ThemeSurface = {
	Color: Color3,
	Material: Enum.Material,
}
Types.ThemeSurface = Type.strictInterface({
	Color = Type.Color3,
	Material = Type.enum(Enum.Material),
})

export type ThemeDefinition = {
	Id: string,
	Name: string,
	Price: number,
	Currency: PseudoEnum.Currency,
	Palette: { [string]: ThemeSurface }, -- keyed by the name of the interior parts it recolors
}
Types.ThemeDefinition = Type.strictInterface({
	Id = Type.string,
	Name = Type.string,
	Price = Type.intersection(Type.integer, Type.numberMin(0)),
	Currency = Type.literal(table.unpack(PseudoEnum.getEnumItems("Currency"))),
	Palette = Type.map(Type.string, Types.ThemeSurface),
})

export type ZoneId = number
Types.ZoneId = Type.intersection(Type.integer, Type.numberConstrained(1, 7))

export type PlacedFurniture = {
	Id: string,
	FurnitureId: string,
	ZoneId: ZoneId,
	CFrame: CFrame, -- of the primary part, relative to its pad
}
Types.PlacedFurniture = Type.strictInterface({
	Id = Type.string,
	FurnitureId = Type.string,
	ZoneId = Types.ZoneId,
	CFrame = Type.CFrame,
})

export type BaseLayout = {
	ThemeId: string,
	Furniture: { PlacedFurniture },
}
Types.BaseLayout = Type.strictInterface({
	ThemeId = Type.string,
	Furniture = Type.array(Types.PlacedFurniture),
})

export type BaseInventory = {
	FurnitureIds: { string },
	ThemeIds: { string },
}
Types.BaseInventory = Type.strictInterface({
	FurnitureIds = Type.array(Type.string),
	ThemeIds = Type.array(Type.string),
})

return Types
