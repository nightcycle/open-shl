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

export type ItemGroup = "clothing" | "costume" | "cosmetics" | "body"
Types.ItemGroup = Type.literal("clothing", "costume", "cosmetics", "body")
export type ItemDefinitionIndex = {
	Group: ItemGroup,
	Category: string,
	Key: string,
}
Types.ItemDefinitionIndex = Type.strictInterface({
	Group = Types.ItemGroup,
	Category = Type.string,
	Key = Type.string,
})

export type TextureGroupDefinition = {
	Key: string,
	Transparency: NumberRange | number?,
	Colors: { Color3 } | true?,
	Materials: { Enum.Material } | true?,
}

Types.TextureGroupDefinition = Type.strictInterface({
	Key = Type.string,
	Transparency = Type.optional(Type.union(Type.numberConstrained(0, 1), Type.NumberRange)),
	Colors = Type.optional(Type.union(Type.array(Type.Color3), Type.literal(true))),
	Materials = Type.optional(Type.union(Type.array(Type.enum(Enum.Material)), Type.literal(true))),
})

export type ItemDefinitionTag = "IsMask"
Types.ItemDefinitionTag = Type.literal("IsMask", "MultiWeld")
export type ItemDefinition = {
	Id: string,
	Name: string?,
	Rarity: PseudoEnum.Rarity?,
	TextureGroups: { TextureGroupDefinition },
	Tags: { ItemDefinitionTag },
}
Types.ItemDefinition = Type.strictInterface({
	Id = Type.string,
	Name = Type.optional(Type.string),
	Rarity = Type.optional(Type.literal(table.unpack(PseudoEnum.getEnumItems("Rarity")))),
	TextureGroups = Type.array(Types.TextureGroupDefinition),
	Tags = Type.array(Types.ItemDefinitionTag),
})

export type Item = {
	DefinitionId: string,
}

Types.Item = Type.strictInterface({
	DefinitionId = Type.string,
})

export type HiddenTag = "Hood" | "Mask" | "MouthCover" | "Hair"
Types.HiddenTag = Type.literal("Hood", "Mask", "MouthCover", "Hair")

export type Appearance = {
	Items: { Item },
	HiddenTags: { HiddenTag },
}

Types.Appearance = Type.strictInterface({
	Items = Type.array(Types.Item),
	HiddenTags = Type.array(Types.HiddenTag),
})

return Types
