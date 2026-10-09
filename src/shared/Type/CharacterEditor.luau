--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
local Types = {}

export type Tag = "IsHero" | "IsSecret" | "IsLensFocused" | "IsEdgeFocused"
Types.Tag = Type.literal("IsHero", "IsSecret", "IsLensFocused", "IsEdgeFocused")

export type FieldDefinition =
	{
		Type: "Text",
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Description: string,
		MaxLength: number?,
	}
	| {
		Type: "Choose",
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Description: string,
		Choices: { MiscType.ChoiceDefinition },
	}
	| {
		Type: "ChoiceList",
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Description: string,
		Choices: { MiscType.ChoiceDefinition },
	}
	| {
		Type: "Color",
		Description: string,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Filtered: { Color3 }?,
	}
	| {
		Type: "Material",
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Filtered: { Enum.Material }?,
	}
	| {
		Type: "Toggle",
		Focus: Tag, -- toggles the specified tag + updates appearance based on value
		Text: string,
		DisabledText: string?,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Style: "Outline" | "Filled",
		Sections: { FieldDefinition }?,
		DisabledSections: { FieldDefinition }?,
	}
	| {
		Type: "Button",
		Text: string,
		ExclusionTags: { Tag }?, -- used to determine if a field is visible
		Alignment: Enum.HorizontalAlignment,
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
			ExclusionTags = exclusionTags,
			Description = Type.string,
			MaxLength = Type.optional(Type.number),
		}),
		Type.strictInterface({
			Type = Type.literal("Choose"),
			ExclusionTags = exclusionTags,
			Description = Type.string,
			Choices = Type.array(MiscType.ChoiceDefinition),
		}),
		Type.strictInterface({
			Type = Type.literal("ChoiceList"),
			ExclusionTags = exclusionTags,
			Description = Type.string,
			Choices = Type.array(MiscType.ChoiceDefinition),
		}),
		Type.strictInterface({
			Type = Type.literal("Color"),
			Description = Type.string,
			ExclusionTags = exclusionTags,
			Filtered = Type.optional(Type.array(Type.Color3)),
		}),
		Type.strictInterface({
			Type = Type.literal("Material"),
			ExclusionTags = exclusionTags,
			Filtered = Type.optional(Type.array(Type.enum(Enum.Material))),
		}),
		Type.strictInterface({
			Type = Type.literal("Toggle"),
			Focus = Types.Tag,
			Text = Type.string,
			DisabledText = Type.optional(Type.string),
			ExclusionTags = exclusionTags,
			Style = Type.literal("Outline", "Filled"),
			Sections = sections,
			DisabledSections = sections,
		}),
		Type.strictInterface({
			Type = Type.literal("Button"),
			Text = Type.string,
			ExclusionTags = exclusionTags,
			Alignment = Type.enum(Enum.HorizontalAlignment),
		})
	)
	Types.FieldDefinition = checkFieldDefinition
end
export type PageDefinition = {
	Key: string, -- used for keeping track of selection / paths
	Title: string?, -- text actually shown on button, uses key otherwise
	ExclusionTags: { Tag }?, -- used to determine if a field is visible
	Properties: { FieldDefinition }?, -- the fields to fill the property panel with
	Children: { PageDefinition }?, -- the buttons that appear in the explorer when this page is selected
}

do -- Types.PageDefinition
	local checkPageDefinition: (unknown) -> (boolean, string?)
	checkPageDefinition = Type.strictInterface({
		Key = Type.string,
		Title = Type.optional(Type.string),
		ExclusionTags = Type.optional(Type.array(Types.Tag)),
		Properties = Type.optional(Type.array(Types.FieldDefinition)),
		Children = Type.optional(Type.array(function(value: unknown): (boolean, string?)
			return checkPageDefinition(value)
		end)),
	})
	Types.PageDefinition = checkPageDefinition
end

return table.freeze(Types)
