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

export type Item = {
	Index: {
		Group: "clothing" | "costume" | "cosmetics" | "body",
		Category: string,
		Item: string,
	},
	Attachment: {
		Root: string,
		Slots: { string }?,
	},
	Texture: {
		Color: Color3,
		Material: Enum.Material,
	},
}

Types.Item = Type.strictInterface({
	Index = Type.strictInterface({
		Group = Type.literal("clothing", "costume", "cosmetics", "body"),
		Category = Type.string,
		Item = Type.string,
	}),
	Attachment = Type.strictInterface({
		Root = Type.string,
		Slots = Type.optional(Type.array(Type.string)),
	}),
	Texture = Type.strictInterface({
		Color = Type.Color3,
		Material = Type.enum(Enum.Material),
	}),
})

export type Appearance = {
	Items: { Item },
}

Types.Appearance = Type.strictInterface({
	Items = Type.array(Types.Item),
})

return Types
