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
	Transparency = Type.numberConstrained(0, 1),
	Color = Type.Color3,
	Material = Type.enum(Enum.Material),
})
export type HiddenTag = "Hood" | "Mask" | "MouthCover" | "Hair"
Types.HiddenTag = Type.literal("Hood", "Mask", "MouthCover", "Hair")

export type ItemDefinitionTag = "IsMask" | HiddenTag
Types.ItemDefinitionTag = Type.union(Type.literal("IsMask"), Types.HiddenTag)

export type FaceSlot = "Eyebrows" | "Eyes" | "Mouth"
Types.FaceSlot = Type.literal("Eyebrows", "Eyes", "Mouth")

-- both variants point at the same list types, otherwise a list read off the union can't be iterated
type ItemDefinitionTextureGroups = { TextureGroupKey }
type ItemDefinitionTags = { ItemDefinitionTag }
export type ItemDefinition =
	{
		Type: "Model",
		Id: string,
		Name: string?,
		Rarity: PseudoEnum.Rarity?,
		TextureGroups: ItemDefinitionTextureGroups,
		Tags: ItemDefinitionTags,
	}
	| {
		Type: "Face",
		Id: string,
		Name: string?,
		Rarity: PseudoEnum.Rarity?,
		TextureGroups: ItemDefinitionTextureGroups,
		Tags: ItemDefinitionTags,
		Slot: FaceSlot,
		Image: string,
	}
Types.ItemDefinition = Type.union(
	Type.strictInterface({
		Type = Type.literal("Model"),
		Id = Type.string,
		Name = Type.optional(Type.string),
		Rarity = Type.optional(Type.literal(table.unpack(PseudoEnum.getEnumItems("Rarity")))),
		TextureGroups = Type.array(Types.TextureGroupKey),
		Tags = Type.array(Types.ItemDefinitionTag),
	}),
	Type.strictInterface({
		Type = Type.literal("Face"),
		Id = Type.string,
		Name = Type.optional(Type.string),
		Rarity = Type.optional(Type.literal(table.unpack(PseudoEnum.getEnumItems("Rarity")))),
		TextureGroups = Type.array(Types.TextureGroupKey),
		Tags = Type.array(Types.ItemDefinitionTag),
		Slot = Types.FaceSlot,
		Image = Type.string,
	})
)

export type Item = {
	DefinitionId: string,
	TextureGroups: { [TextureGroupKey]: TextureGroup? },
}

Types.Item = Type.strictInterface({
	DefinitionId = Type.string,
	TextureGroups = Type.map(Types.TextureGroupKey, Types.TextureGroup),
})

export type TransitionType = PseudoEnum.TransitionType
Types.TransitionType = Type.literal(table.unpack(PseudoEnum.getEnumItems("TransitionType")))

export type DeathTransition = {
	Style: PseudoEnum.DeathStyle,
}
Types.DeathTransition = Type.strictInterface({
	Style = Type.literal(table.unpack(PseudoEnum.getEnumItems("DeathStyle"))),
})

export type TransformationTransition = {
	Style: PseudoEnum.TransformationStyle,
}
Types.TransformationTransition = Type.strictInterface({
	Style = Type.literal(table.unpack(PseudoEnum.getEnumItems("TransformationStyle"))),
})

export type Transition = DeathTransition | TransformationTransition
Types.Transition = Type.union(Types.DeathTransition, Types.TransformationTransition)

-- a missing transition plays the default, a missing face slot shows the neutral image
export type Appearance = {
	Items: { Item },
	SkinColor: Color3,
	Transitions: {
		Death: DeathTransition?,
		Transformation: TransformationTransition?,
	},
	HiddenTags: { HiddenTag },
}

Types.Appearance = Type.strictInterface({
	Items = Type.array(Types.Item),
	SkinColor = Type.Color3,
	Transitions = Type.strictInterface({
		Death = Type.optional(Types.DeathTransition),
		Transformation = Type.optional(Types.TransformationTransition),
	}),
	HiddenTags = Type.array(Types.HiddenTag),
})

return Types
