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
	CharacterId: string?, -- only on a suit display: the character whose costume it wears
	ArtifactId: string?, -- only on a pedestal: the artifact that sits on it
}
Types.PlacedFurniture = Type.strictInterface({
	Id = Type.string,
	FurnitureId = Type.string,
	ZoneId = Types.ZoneId,
	CFrame = Type.CFrame,
	CharacterId = Type.optional(Type.string),
	ArtifactId = Type.optional(Type.string),
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

-- a door of the apartment lobby + the spot in the tower the residence behind it is built at
export type ResidenceId =
	"N1"
	| "N2"
	| "N3"
	| "N4"
	| "N5"
	| "N6"
	| "N7"
	| "N8"
	| "N9"
	| "N10"
	| "S1"
	| "S2"
	| "S3"
	| "S4"
	| "S5"
	| "S6"
	| "S7"
	| "S8"
	| "S9"
	| "S10"
Types.ResidenceId = Type.literal(
	"N1",
	"N2",
	"N3",
	"N4",
	"N5",
	"N6",
	"N7",
	"N8",
	"N9",
	"N10",
	"S1",
	"S2",
	"S3",
	"S4",
	"S5",
	"S6",
	"S7",
	"S8",
	"S9",
	"S10"
)

return Types
