--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

export type ItemCategory = "clothing" | "costume" | "cosmetics" | "body"
export type ItemDefinitionIndex = {
	Group: ItemCategory,
	Category: string,
	Item: string,
}
Types.ItemDefinitionIndex = Type.strictInterface({
	Group = Type.literal("clothing", "costume", "cosmetics", "body"),
	Category = Type.string,
	Item = Type.string,
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
Types.ItemDefinitionTag = Type.literal("IsMask")
export type ItemDefinition = {
	Id: string,
	TextureGroups: { TextureGroupDefinition },
	Tags: { ItemDefinitionTag },
}
Types.ItemDefinition = Type.strictInterface({
	Id = Type.string,
	TextureGroups = Type.array(Types.TextureGroupDefinition),
	Tags = Type.array(Types.ItemDefinitionTag),
})

export type Item = {
	DefinitionId: string,
	Attachment: {
		Root: string,
		Slots: { string }?,
	},
}

Types.Item = Type.strictInterface({
	DefinitionId = Type.string,
	Attachment = Type.strictInterface({
		Root = Type.string,
		Slots = Type.optional(Type.array(Type.string)),
	}),
})

export type Appearance = {
	Items: { Item },
}

Types.Appearance = Type.strictInterface({
	Items = Type.array(Types.Item),
})

return Types
