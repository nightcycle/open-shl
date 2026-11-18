--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
local Types = {}

export type Tag =
	"IsSuper"
	| "IsSecret"
	| "IsLensFocused"
	| "IsEdgeFocused"
	| "HasLenses"
	| "HasNoLenses"
	| "IsItemAdded"
	| "IsColorMatched" -- the identities share one skin + one hair color
Types.Tag = Type.literal(
	"IsSuper",
	"IsSecret",
	"IsLensFocused",
	"IsEdgeFocused",
	"HasLenses",
	"HasNoLenses",
	"IsItemAdded",
	"IsColorMatched"
)

export type ButtonStyle = "Outline" | "Filled"
Types.ButtonStyle = Type.literal("Outline", "Filled")

export type WearRule = "Single" | "Multi" | "MultiHair"
Types.WearRule = Type.literal("Single", "Multi", "MultiHair")

export type ProfileKey = "Name" | "Backstory"
Types.ProfileKey = Type.literal("Name", "Backstory")

export type AlignmentAxis = "Morality" | "Order"
Types.AlignmentAxis = Type.literal("Morality", "Order")

export type Morality = "Evil" | "Neutral" | "Good"
Types.Morality = Type.literal("Evil", "Neutral", "Good")

export type Order = "Chaotic" | "Neutral" | "Lawful"
Types.Order = Type.literal("Chaotic", "Neutral", "Lawful")

export type ScaleAxis = "Height" | "Width"
Types.ScaleAxis = Type.literal("Height", "Width")

-- a binding is the piece of the character a field edits
export type ProfileBinding = {
	Type: "Profile",
	Key: ProfileKey,
}
Types.ProfileBinding = Type.strictInterface({
	Type = Type.literal("Profile"),
	Key = Types.ProfileKey,
})

export type AlignmentBinding = {
	Type: "Alignment",
	Axis: AlignmentAxis,
}
Types.AlignmentBinding = Type.strictInterface({
	Type = Type.literal("Alignment"),
	Axis = Types.AlignmentAxis,
})

export type SkinColorBinding = {
	Type: "SkinColor",
}
Types.SkinColorBinding = Type.strictInterface({
	Type = Type.literal("SkinColor"),
})

export type TransitionBinding = {
	Type: "Transition",
	TransitionType: AppearanceType.TransitionType,
}
Types.TransitionBinding = Type.strictInterface({
	Type = Type.literal("Transition"),
	TransitionType = AppearanceType.TransitionType,
})

export type PowersBinding = {
	Type: "Powers",
	Group: PowerType.PowerGroup,
}
Types.PowersBinding = Type.strictInterface({
	Type = Type.literal("Powers"),
	Group = PowerType.PowerGroup,
})

export type PowerLimitBinding = {
	Type: "PowerLimit",
}
Types.PowerLimitBinding = Type.strictInterface({
	Type = Type.literal("PowerLimit"),
})

export type ItemTextureBinding = {
	Type: "ItemTexture",
	Group: AppearanceType.TextureGroupKey?, -- uses the group in focus otherwise
}
Types.ItemTextureBinding = Type.strictInterface({
	Type = Type.literal("ItemTexture"),
	Group = Type.optional(AppearanceType.TextureGroupKey),
})

-- the choices of a height are heights, the choices of a width are how broad the body is for its height
export type ScaleBinding = {
	Type: "Scale",
	Axis: ScaleAxis,
}
Types.ScaleBinding = Type.strictInterface({
	Type = Type.literal("Scale"),
	Axis = Types.ScaleAxis,
})

export type ChooseBinding = AlignmentBinding | TransitionBinding | ScaleBinding
Types.ChooseBinding = Type.union(Types.AlignmentBinding, Types.TransitionBinding, Types.ScaleBinding)

export type ColorBinding = SkinColorBinding | ItemTextureBinding
Types.ColorBinding = Type.union(Types.SkinColorBinding, Types.ItemTextureBinding)

export type Binding =
	ProfileBinding
	| AlignmentBinding
	| SkinColorBinding
	| TransitionBinding
	| PowersBinding
	| PowerLimitBinding
	| ItemTextureBinding
	| ScaleBinding
Types.Binding = Type.union(
	Types.ProfileBinding,
	Types.AlignmentBinding,
	Types.SkinColorBinding,
	Types.TransitionBinding,
	Types.PowersBinding,
	Types.PowerLimitBinding,
	Types.ItemTextureBinding,
	Types.ScaleBinding
)

-- one of the looks a pattern picker offers a texture group: a material + the image that's drawn over it, if any. the
-- pattern is the key of one of the game's, a choice without an icon is a plain swatch
export type PatternChoice = {
	Name: string,
	Material: Enum.Material,
	Pattern: string?,
	Icon: MiscType.IconDefinition?,
}
Types.PatternChoice = Type.strictInterface({
	Name = Type.string,
	Material = Type.enum(Enum.Material),
	Pattern = Type.optional(Type.string),
	Icon = Type.optional(MiscType.IconDefinition),
})

export type FieldDefinition =
	{
		Type: "Text",
		Binding: ProfileBinding,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Description: string?,
		MaxLength: number?,
		IsMultiLine: boolean?,
	}
	| {
		Type: "Choose",
		Binding: ChooseBinding,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Description: string?,
		Choices: { MiscType.ChoiceDefinition },
		IsVertical: boolean?, -- stacks the choices as rows, they sit side by side otherwise
	}
	| {
		Type: "ChoiceList",
		Binding: PowersBinding,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Description: string?,
		Choices: { MiscType.ChoiceDefinition },
	}
	| {
		Type: "Color",
		Binding: ColorBinding,
		Description: string?,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Filtered: { Color3 }?, -- the colors that are left out of the palette
	}
	| {
		Type: "Material",
		Binding: ItemTextureBinding,
		Description: string?,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Filtered: { Enum.Material }?, -- the materials that are left out of the palette
	}
	| {
		Type: "Pattern", -- offers the pattern choices of the game's editor
		Binding: ItemTextureBinding,
		Description: string?,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
	}
	| {
		Type: "Toggle",
		Focus: Tag, -- toggles the specified tag + updates appearance based on value
		Text: string,
		DisabledText: string?, -- shown while the tag is on, when pressing it turns the tag off
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Style: ButtonStyle,
		Sections: { FieldDefinition }?, -- the fields that follow it while the tag is on
		DisabledSections: { FieldDefinition }?, -- the fields that follow it while the tag is off
	}
	| {
		Type: "GenerateAlias",
		Binding: ProfileBinding,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
	}
	| {
		Type: "SectionHeader",
		Text: string,
		Binding: PowerLimitBinding?, -- the text is written for the default limit
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
	}
do -- Types.FieldDefinition
	local checkFieldDefinition: (unknown) -> (boolean, string?)
	local sections = Type.optional(Type.array(function(value: unknown): (boolean, string?)
		return checkFieldDefinition(value)
	end))
	local exclusionTags = Type.optional(Type.array(Types.Tag))

	checkFieldDefinition = Type.union(
		Type.strictInterface({
			Type = Type.literal("Text"),
			Binding = Types.ProfileBinding,
			ExclusionTags = exclusionTags,
			Description = Type.optional(Type.string),
			MaxLength = Type.optional(Type.number),
			IsMultiLine = Type.optional(Type.boolean),
		}),
		Type.strictInterface({
			Type = Type.literal("Choose"),
			Binding = Types.ChooseBinding,
			ExclusionTags = exclusionTags,
			Description = Type.optional(Type.string),
			Choices = Type.array(MiscType.ChoiceDefinition),
			IsVertical = Type.optional(Type.boolean),
		}),
		Type.strictInterface({
			Type = Type.literal("ChoiceList"),
			Binding = Types.PowersBinding,
			ExclusionTags = exclusionTags,
			Description = Type.optional(Type.string),
			Choices = Type.array(MiscType.ChoiceDefinition),
		}),
		Type.strictInterface({
			Type = Type.literal("Color"),
			Binding = Types.ColorBinding,
			Description = Type.optional(Type.string),
			ExclusionTags = exclusionTags,
			Filtered = Type.optional(Type.array(Type.Color3)),
		}),
		Type.strictInterface({
			Type = Type.literal("Material"),
			Binding = Types.ItemTextureBinding,
			Description = Type.optional(Type.string),
			ExclusionTags = exclusionTags,
			Filtered = Type.optional(Type.array(Type.enum(Enum.Material))),
		}),
		Type.strictInterface({
			Type = Type.literal("Pattern"),
			Binding = Types.ItemTextureBinding,
			Description = Type.optional(Type.string),
			ExclusionTags = exclusionTags,
		}),
		Type.strictInterface({
			Type = Type.literal("Toggle"),
			Focus = Types.Tag,
			Text = Type.string,
			DisabledText = Type.optional(Type.string),
			ExclusionTags = exclusionTags,
			Style = Types.ButtonStyle,
			Sections = sections,
			DisabledSections = sections,
		}),
		Type.strictInterface({
			Type = Type.literal("GenerateAlias"),
			Binding = Types.ProfileBinding,
			ExclusionTags = exclusionTags,
		}),
		Type.strictInterface({
			Type = Type.literal("SectionHeader"),
			Text = Type.string,
			Binding = Type.optional(Types.PowerLimitBinding),
			ExclusionTags = exclusionTags,
		})
	)
	Types.FieldDefinition = checkFieldDefinition
end
export type PageDefinition =
	{
		Type: "Default",
		Key: string, -- used for keeping track of selection / paths
		Title: string?, -- text actually shown on button, uses key otherwise
		ExclusionTags: { Tag }?, -- used to determine if a page is visible
		IsShared: boolean?, -- what's edited on it goes to every identity, not just the one in focus
		Fields: { FieldDefinition }?, -- the fields to fill the property panel with
		Children: { PageDefinition }?, -- the buttons that appear in the explorer when this page is selected
	}
	| {
		Type: "Item",
		DefinitionId: string,
		WearRule: WearRule, -- what happens to the worn items of its category when it's added
		ExclusionTags: { Tag }?, -- used to determine if a page is visible
		IsShared: boolean?, -- the item is worn + edited in every identity, not just the one in focus
		StandInId: string?, -- the item that's worn in its place once it's taken off, its category is never left bare
		Fields: { FieldDefinition }?, -- the fields to fill the property panel with
	}

do -- Types.PageDefinition
	local checkPageDefinition: (unknown) -> (boolean, string?)
	checkPageDefinition = Type.union(
		Type.strictInterface({
			Type = Type.literal("Default"),
			Key = Type.string,
			Title = Type.optional(Type.string),
			ExclusionTags = Type.optional(Type.array(Types.Tag)),
			IsShared = Type.optional(Type.boolean),
			Fields = Type.optional(Type.array(Types.FieldDefinition)),
			Children = Type.optional(Type.array(function(value: unknown): (boolean, string?)
				return checkPageDefinition(value)
			end)),
		}),
		Type.strictInterface({
			Type = Type.literal("Item"),
			DefinitionId = Type.string,
			WearRule = Types.WearRule,
			ExclusionTags = Type.optional(Type.array(Types.Tag)),
			IsShared = Type.optional(Type.boolean),
			StandInId = Type.optional(Type.string),
			Fields = Type.optional(Type.array(Types.FieldDefinition)),
		})
	)
	Types.PageDefinition = checkPageDefinition
end

-- the body sizes a game offers: its heights, how broad a body can be for its height (a width is a height times one of
-- these) + what a body is built at until one is picked
export type ScaleDefinition = {
	Heights: { number },
	WidthRatios: { number },
	Default: AppearanceType.Scale,
}
Types.ScaleDefinition = Type.strictInterface({
	Heights = Type.array(Type.numberPositive),
	WidthRatios = Type.array(Type.numberPositive),
	Default = AppearanceType.Scale,
})

-- where the powers of a character get their colors when a game has none to pick for a power: off two texture groups of
-- what one of its identities wears in a category, whichever identity is out. what's held is drawn in the one, what it
-- throws in the other
export type PowerColorSource = {
	IdentityKey: CharacterType.IdentityKey,
	Group: AppearanceType.ItemGroup,
	Category: string,
	Primary: AppearanceType.TextureGroupKey,
	Secondary: AppearanceType.TextureGroupKey,
}
Types.PowerColorSource = Type.strictInterface({
	IdentityKey = CharacterType.IdentityKey,
	Group = AppearanceType.ItemGroup,
	Category = Type.string,
	Primary = AppearanceType.TextureGroupKey,
	Secondary = AppearanceType.TextureGroupKey,
})

-- what a game's editor is: how much of a name + a backstory it keeps + its pages, from the root down. a game without
-- body sizes has no scale, one without patterns has no choices for a pattern picker, one whose powers are colored by
-- a pick of their own has no source for their colors
export type EditorDefinition = {
	MaxNameLength: number,
	MaxBackstoryLength: number,
	Scale: ScaleDefinition?,
	PatternChoices: { PatternChoice }?, -- in the order a picker lists them
	PowerColorSource: PowerColorSource?,
	Root: PageDefinition,
}
Types.EditorDefinition = Type.strictInterface({
	MaxNameLength = Type.intersection(Type.integer, Type.numberPositive),
	MaxBackstoryLength = Type.intersection(Type.integer, Type.numberPositive),
	Scale = Type.optional(Types.ScaleDefinition),
	PatternChoices = Type.optional(Type.array(Types.PatternChoice)),
	PowerColorSource = Type.optional(Types.PowerColorSource),
	Root = Types.PageDefinition,
})

export type Entitlements = {
	PowerLimit: number,
	HasMultiHair: boolean,
}
Types.Entitlements = Type.strictInterface({
	PowerLimit = Type.intersection(Type.integer, Type.numberMin(0)),
	HasMultiHair = Type.boolean,
})

export type EditorState = {
	Character: CharacterType.Character, -- the draft that gets saved
	SavedCharacter: CharacterType.Character, -- what the draft started out as
	IdentityKey: CharacterType.IdentityKey, -- the identity in focus
	Path: string, -- the page that's open, "" is the root
	PendingItem: AppearanceType.Item?, -- the item of the open page while it's tried on, it isn't worn yet
	FocusedGroup: AppearanceType.TextureGroupKey?, -- the texture group the palettes edit, the item's main one otherwise
	Entitlements: Entitlements,
}
Types.EditorState = Type.strictInterface({
	Character = CharacterType.Character,
	SavedCharacter = CharacterType.Character,
	IdentityKey = CharacterType.IdentityKey,
	Path = Type.string,
	PendingItem = Type.optional(AppearanceType.Item),
	FocusedGroup = Type.optional(AppearanceType.TextureGroupKey),
	Entitlements = Types.Entitlements,
})

export type PowerValue = {
	Id: string,
	Color: Color3?,
}
Types.PowerValue = Type.strictInterface({
	Id = Type.string,
	Color = Type.optional(Type.Color3),
})

export type FieldValue =
	{
		Type: "Text",
		Text: string,
	}
	| {
		Type: "Choice",
		Value: any, -- the value of the choice that's picked, nil when none of them is
	}
	| {
		Type: "Color",
		Color: Color3?, -- nil when there's nothing to color
	}
	| {
		Type: "Material",
		Material: Enum.Material?, -- nil when there's nothing to texture
	}
	| {
		Type: "Pattern",
		Material: Enum.Material?, -- nil when there's nothing to texture
		Pattern: string?, -- nil when no image is drawn over the color
	}
	| {
		Type: "Toggle",
		IsSelected: boolean,
	}
	| {
		Type: "Powers",
		Powers: { [string]: PowerValue }, -- the powers of the field's group that are held, by id
		Count: number, -- how many powers the character holds across every group
		Limit: number,
	}
Types.FieldValue = Type.union(
	Type.strictInterface({
		Type = Type.literal("Text"),
		Text = Type.string,
	}),
	Type.strictInterface({
		Type = Type.literal("Choice"),
		Value = Type.optional(Type.any),
	}),
	Type.strictInterface({
		Type = Type.literal("Color"),
		Color = Type.optional(Type.Color3),
	}),
	Type.strictInterface({
		Type = Type.literal("Material"),
		Material = Type.optional(Type.enum(Enum.Material)),
	}),
	Type.strictInterface({
		Type = Type.literal("Pattern"),
		Material = Type.optional(Type.enum(Enum.Material)),
		Pattern = Type.optional(Type.string),
	}),
	Type.strictInterface({
		Type = Type.literal("Toggle"),
		IsSelected = Type.boolean,
	}),
	Type.strictInterface({
		Type = Type.literal("Powers"),
		Powers = Type.map(Type.string, Types.PowerValue),
		Count = Type.number,
		Limit = Type.number,
	})
)

export type FieldEdit =
	{
		Type: "Text",
		Text: string,
	}
	| {
		Type: "Choice",
		Value: any, -- the value of the choice that was pressed
	}
	| {
		Type: "Color",
		Color: Color3,
	}
	| {
		Type: "Material",
		Material: Enum.Material,
	}
	| {
		Type: "Pattern", -- the material + the pattern of the choice that was pressed
		Material: Enum.Material,
		Pattern: string?,
	}
	| {
		Type: "Toggle",
		IsSelected: boolean,
	}
	| {
		Type: "Power",
		Id: string,
		IsSelected: boolean,
	}
	| {
		Type: "PowerColor",
		Id: string,
		Color: Color3,
	}
	| {
		Type: "Alias",
		Seed: number, -- the same seed always makes the same alias
	}
Types.FieldEdit = Type.union(
	Type.strictInterface({
		Type = Type.literal("Text"),
		Text = Type.string,
	}),
	Type.strictInterface({
		Type = Type.literal("Choice"),
		Value = Type.any,
	}),
	Type.strictInterface({
		Type = Type.literal("Color"),
		Color = Type.Color3,
	}),
	Type.strictInterface({
		Type = Type.literal("Material"),
		Material = Type.enum(Enum.Material),
	}),
	Type.strictInterface({
		Type = Type.literal("Pattern"),
		Material = Type.enum(Enum.Material),
		Pattern = Type.optional(Type.string),
	}),
	Type.strictInterface({
		Type = Type.literal("Toggle"),
		IsSelected = Type.boolean,
	}),
	Type.strictInterface({
		Type = Type.literal("Power"),
		Id = Type.string,
		IsSelected = Type.boolean,
	}),
	Type.strictInterface({
		Type = Type.literal("PowerColor"),
		Id = Type.string,
		Color = Type.Color3,
	}),
	Type.strictInterface({
		Type = Type.literal("Alias"),
		Seed = Type.number,
	})
)

return table.freeze(Types)
