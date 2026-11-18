--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type ShopTab = EconomyType.ShopTab
local Types = {}

-- a part of a card, in scale of it
export type Area = {
	Position: UDim2,
	Size: UDim2,
}
Types.Area = Type.strictInterface({
	Position = Type.UDim2,
	Size = Type.UDim2,
})

export type Picture = {
	Image: string, -- an image that isn't in the asset table is one the checker lets through
	Position: UDim2,
	Size: UDim2,
	Rotation: number?,
}
Types.Picture = Type.strictInterface({
	Image = Type.string,
	Position = Type.UDim2,
	Size = Type.UDim2,
	Rotation = Type.optional(Type.number),
})

-- what's drawn on the card of one product
export type CardInfo = {
	ProductId: string,
	Pictures: { Picture },
	-- what's pressed to buy it. it's the picture in the middle + never the whole card
	Button: Area,
}
Types.CardInfo = Type.strictInterface({
	ProductId = Type.string,
	Pictures = Type.array(Types.Picture),
	Button = Types.Area,
})

-- a tab + the row of cards it shows
export type TabInfo = {
	Tab: ShopTab,
	Text: string,
	Image: string, -- the art of its button, which has the text drawn into it
	TagSize: UDim2, -- the tag that covers that text, in scale of the button
	Tile: string, -- what every card of it is drawn on
	CardSize: UDim2,
	CardSizeConstraint: Enum.SizeConstraint,
	Padding: UDim, -- between two cards
	Caption: Area,
	Cards: { CardInfo }, -- left to right
}
Types.TabInfo = Type.strictInterface({
	Tab = EconomyType.ShopTab,
	Text = Type.string,
	Image = Type.string,
	TagSize = Type.UDim2,
	Tile = Type.string,
	CardSize = Type.UDim2,
	CardSizeConstraint = Type.enum(Enum.SizeConstraint),
	Padding = Type.UDim,
	Caption = Types.Area,
	Cards = Type.array(Types.CardInfo),
})
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
