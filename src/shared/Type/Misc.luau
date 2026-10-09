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

export type IconDefinition =
	{
		Type: "Sprite",
		SheetUrl: string,
		Size: Vector2,
		Position: Vector2,
	}
	| {
		Type: "Decal",
		Url: string,
	}

Types.IconDefinition = Type.union(
	Type.strictInterface({
		Type = Type.literal("Sprite"),
		SheetUrl = Type.string,
		Size = Type.Vector2,
		Position = Type.Vector2,
	}),
	Type.strictInterface({
		Type = Type.literal("Decal"),
		Url = Type.string,
	})
)

export type ChoiceDefinition =
	{
		Type: "Text",
		Value: any,
		Text: string,
	}
	| {
		Type: "Icon",
		Value: any,
		Icon: IconDefinition,
	}
	| {
		Type: "TextIcon",
		Value: any,
		Text: string,
	}

Types.ChoiceDefinition = Type.union(
	Type.strictInterface({
		Type = Type.literal("Text"),
		Value = Type.any,
		Text = Type.string,
	}),
	Type.strictInterface({
		Type = Type.literal("Icon"),
		Value = Type.any,
		Icon = Types.IconDefinition,
	}),
	Type.strictInterface({
		Type = Type.literal("TextIcon"),
		Value = Type.any,
		Text = Type.string,
		Icon = Types.IconDefinition,
	})
)

return Types
