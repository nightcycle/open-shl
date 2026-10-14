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

export type TextureGroupKey = "Primary" | "Secondary" | "Tertiary" | "Hair" | "Skin"
Types.TextureGroupKey = Type.literal("Primary", "Secondary", "Tertiary", "Hair", "Skin")
export type TextureGroup = {
	Transparency: number,
	Color: Color3,
	Material: Enum.Material,
}

Types.TextureGroup = Type.strictInterface({
	Transparency = Type.optional(Type.numberConstrained(0, 1)),
	Color = Type.optional(Type.Color3),
	Material = Type.optional(Type.enum(Enum.Material)),
})
export type HiddenTag = "Hood" | "Mask" | "MouthCover" | "Hair"
Types.HiddenTag = Type.literal("Hood", "Mask", "MouthCover", "Hair")

export type ItemDefinitionTag = "IsMask" | HiddenTag
Types.ItemDefinitionTag = Type.union(Type.literal("IsMask"), Types.HiddenTag)

export type ItemDefinition = {
	Id: string,
	Name: string?,
	Rarity: PseudoEnum.Rarity?,
	TextureGroups: { TextureGroupKey },
	Tags: { ItemDefinitionTag },
}
Types.ItemDefinition = Type.strictInterface({
	Id = Type.string,
	Name = Type.optional(Type.string),
	Rarity = Type.optional(Type.literal(table.unpack(PseudoEnum.getEnumItems("Rarity")))),
	TextureGroups = Type.array(Types.TextureGroupKey),
	Tags = Type.array(Types.ItemDefinitionTag),
})

export type Item = {
	DefinitionId: string,
	TextureGroups: { [TextureGroupKey]: TextureGroup? },
}

Types.Item = Type.strictInterface({
	DefinitionId = Type.string,
	TextureGroups = Type.map(Types.TextureGroupKey, Types.TextureGroup),
})

export type TransitionType = "Death" | "Transformation"
Types.TransitionType = Type.literal("Death", "Transformation")

export type Transition = {}
Types.Transition = Type.strictInterface({})

export type Appearance = {
	Items: { Item },
	Transitions: {
		[TransitionType]: Transition?,
	},
	HiddenTags: { HiddenTag },
}

Types.Appearance = Type.strictInterface({
	Items = Type.array(Types.Item),
	Transitions = Type.map(Types.TransitionType, Types.Transition),
	HiddenTags = Type.array(Types.HiddenTag),
})

return Types
