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
	Pattern: string?, -- the key of one of the game's pattern images, drawn over the color
}

Types.TextureGroup = Type.strictInterface({
	Transparency = Type.numberConstrained(0, 1),
	Color = Type.Color3,
	Material = Type.enum(Enum.Material),
	Pattern = Type.optional(Type.string),
})
-- an image a game draws over the color of a texture group, a group names it by its key
export type PatternDefinition = {
	Key: string,
	Name: string,
	Image: string,
}
Types.PatternDefinition = Type.strictInterface({
	Key = Type.string,
	Name = Type.string,
	Image = Type.string,
})

export type HiddenTag = "Hood" | "Mask" | "MouthCover" | "Hair"
Types.HiddenTag = Type.literal("Hood", "Mask", "MouthCover", "Hair")

export type ItemDefinitionTag = "IsMask" | HiddenTag
Types.ItemDefinitionTag = Type.union(Type.literal("IsMask"), Types.HiddenTag)

-- a game draws a face out of pieces or as one picture, which is the "Face" slot
export type FaceSlot = "Eyebrows" | "Eyes" | "Mouth" | "Face"
Types.FaceSlot = Type.literal("Eyebrows", "Eyes", "Mouth", "Face")

-- the order a game lists the items of a category in, by key, + how many of them from the top are anybody's. an item
-- that's left out is on no list of the game
export type ItemOrder = {
	Keys: { string },
	StarterCount: number?, -- every one of them is anybody's without
}
Types.ItemOrder = Type.intersection(
	Type.strictInterface({
		Keys = Type.array(Type.string),
		StarterCount = Type.optional(Type.intersection(Type.integer, Type.numberMin(0))),
	}),
	function(value: ItemOrder): (boolean, string?)
		if value.StarterCount ~= nil and value.StarterCount > #value.Keys then
			return false, `more starters than there are keys`
		end
		return true
	end
)

-- the faces a game draws: its slots in the order they're listed, which is from the top of a face down, the category +
-- the images of each, and the names of the ones that don't go by their image's. a game that lists a category in an
-- order of its own says so under "<group>/<category>", every other one is listed the way the library holds it
export type FaceCatalogue = {
	Slots: { FaceSlot },
	Categories: { [FaceSlot]: string },
	Images: { [FaceSlot]: { [string]: string } },
	Names: { [string]: string },
	Defaults: { [FaceSlot]: string }, -- the image a slot shows with nothing worn in it, a slot without one stays bare
	Tints: { [FaceSlot]: Color3 }, -- the slots that take a color + the one each is drawn in until it's given another
	Orders: { [string]: ItemOrder }?,
}
Types.FaceCatalogue = Type.strictInterface({
	Slots = Type.array(Types.FaceSlot),
	Categories = Type.map(Types.FaceSlot, Type.string),
	Images = Type.map(Types.FaceSlot, Type.map(Type.string, Type.string)),
	Names = Type.map(Type.string, Type.string),
	Defaults = Type.map(Types.FaceSlot, Type.string),
	Tints = Type.map(Types.FaceSlot, Type.Color3),
	Orders = Type.optional(Type.map(Type.string, Types.ItemOrder)),
})

-- both variants point at the same list types, otherwise a list read off the union can't be iterated. the order + the
-- starter mark are only there in a game that lists the category of the item in an order of its own
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
		IsBodyHidden: boolean?, -- it stands for the part of the body it's worn on, which isn't drawn under it
		ShaveHead: boolean?, -- hair isn't drawn under it
		Order: number?, -- its place on the list of its category
		IsStarter: boolean?, -- anybody's
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
		Order: number?,
		IsStarter: boolean?,
	}
Types.ItemDefinition = Type.union(
	Type.strictInterface({
		Type = Type.literal("Model"),
		Id = Type.string,
		Name = Type.optional(Type.string),
		Rarity = Type.optional(Type.literal(table.unpack(PseudoEnum.getEnumItems("Rarity")))),
		TextureGroups = Type.array(Types.TextureGroupKey),
		Tags = Type.array(Types.ItemDefinitionTag),
		IsBodyHidden = Type.optional(Type.boolean),
		ShaveHead = Type.optional(Type.boolean),
		Order = Type.optional(Type.intersection(Type.integer, Type.numberPositive)),
		IsStarter = Type.optional(Type.boolean),
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
		Order = Type.optional(Type.intersection(Type.integer, Type.numberPositive)),
		IsStarter = Type.optional(Type.boolean),
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

-- how tall + how broad the body is built, against the rig as it comes. which sizes there are is the game's own
export type Scale = {
	Height: number,
	Width: number,
}
Types.Scale = Type.strictInterface({
	Height = Type.numberPositive,
	Width = Type.numberPositive,
})

-- a missing transition plays the default, a missing face slot shows the neutral image. a game without body sizes
-- leaves the scale out
export type Appearance = {
	Items: { Item },
	SkinColor: Color3,
	Scale: Scale?,
	Transitions: {
		Death: DeathTransition?,
		Transformation: TransformationTransition?,
	},
	HiddenTags: { HiddenTag },
}

Types.Appearance = Type.strictInterface({
	Items = Type.array(Types.Item),
	SkinColor = Type.Color3,
	Scale = Type.optional(Types.Scale),
	Transitions = Type.strictInterface({
		Death = Type.optional(Types.DeathTransition),
		Transformation = Type.optional(Types.TransformationTransition),
	}),
	HiddenTags = Type.array(Types.HiddenTag),
})

return Types
