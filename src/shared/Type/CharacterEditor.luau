--!strict
--!native
-- Services
-- Packages
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

export type ImageDefinition =
	{
		Type: "Sprite",
		Sheet: string,
		Size: Vector2,
		Offset: Vector2,
	}
	| {
		Type: "Decal",
		Image: string,
	}

export type ChoiceDefinition = {
	Value: any,
	Text: string,
	Icon: ImageDefinition?,
}

export type PropertyDefinition =
	{
		Type: "Text",
		Description: string,
		MaxLength: number?,
	}
	| {
		Type: "Choose",
		Description: string,
		Choices: { ChoiceDefinition },
	}
	| {
		Type: "ChoiceList",
		Description: string,
		Choices: { ChoiceDefinition },
	}
	| {
		Type: "Color",
		Filtered: { Color3 }?,
	}
	| {
		Type: "Material",
		Filtered: { Enum.Material }?,
	}
	| {
		Type: "Toggle",
		StateKey: string,
		Text: string,
		DisabledText: string?,
		Style: "Outline" | "Filled",
		Sections: { PropertyDefinition }?,
		DisabledSections: { PropertyDefinition }?,
	}
	| {
		Type: "Button",
		Text: string,
		Alignment: Enum.HorizontalAlignment,
	}

export type PageDefinition = {
	Key: string, -- used for keeping track of selection / paths
	Title: string?, -- text actually shown on button, uses key otherwise
	StateKey: string?, -- used to determine if button is shaded as green / enabled
	Properties: { PropertyDefinition }?, -- the fields to fill the property panel with
	Children: { PageDefinition }?, -- the buttons that appear in the explorer when this page is selected
}

return Types
