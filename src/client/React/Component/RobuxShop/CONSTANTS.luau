--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/RobuxShop/Types")
export type Area = Types.Area
export type Picture = Types.Picture
export type CardInfo = Types.CardInfo
export type TabInfo = Types.TabInfo
-- Constants
local SHOP_IMAGES = Image.shl3.ui.shop
-- the picture in the middle of a card, which is the part of it that's pressed
local PICTURE_AREA: Area = {
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.5, 0.5),
}
-- the same for the credits, which sit 3 pixels lower than their scale says
local CREDIT_BUTTON_AREA: Area = {
	Position = UDim2.new(0.5, 0, 0.4403, 3),
	Size = UDim2.fromScale(0.4, 0.5),
}
-- the legacy shop as it was laid out: the passes first, the credits from the largest pile down. every number is in
-- scale of the card it's on
local TABS: { TabInfo } = {
	{
		Tab = "Gamepasses",
		Text = "GAMEPASSES",
		Image = SHOP_IMAGES["gamepasses-button.png"],
		TagSize = UDim2.fromScale(0.9, 0.8),
		Tile = SHOP_IMAGES["gamepass-tile.png"],
		-- a square of the height of the list
		CardSize = UDim2.fromScale(0.85, 0.85),
		CardSizeConstraint = Enum.SizeConstraint.RelativeYY,
		Padding = UDim.new(0.007, 0),
		Caption = {
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(0.8, 0.25),
		},
		Cards = {
			{
				ProductId = "gamepasses_advanced-roleplay",
				Pictures = {
					{
						Image = SHOP_IMAGES["gamepass-adv-rp.png"],
						Position = PICTURE_AREA.Position,
						Size = PICTURE_AREA.Size,
					},
				},
				Button = PICTURE_AREA,
			},
			{
				ProductId = "gamepasses_extra-character-slots",
				Pictures = {
					{
						Image = SHOP_IMAGES["gamepass-double-slots.png"],
						Position = PICTURE_AREA.Position,
						Size = PICTURE_AREA.Size,
					},
				},
				Button = PICTURE_AREA,
			},
			{
				ProductId = "gamepasses_extra-powers",
				Pictures = {
					{
						Image = SHOP_IMAGES["gamepass-extra-power-slots.png"],
						Position = PICTURE_AREA.Position,
						Size = PICTURE_AREA.Size,
					},
				},
				Button = PICTURE_AREA,
			},
		},
	},
	{
		Tab = "Credits",
		Text = "CREDITS",
		Image = SHOP_IMAGES["credits-button.png"],
		TagSize = UDim2.fromScale(0.8, 0.8),
		Tile = SHOP_IMAGES["currency-tile.png"],
		-- a square of the width of the canvas, which is three lists wide
		CardSize = UDim2.fromScale(0.12, 0.12),
		CardSizeConstraint = Enum.SizeConstraint.RelativeXX,
		Padding = UDim.new(0.001, 0),
		Caption = {
			Position = UDim2.fromScale(0.5, 1.02),
			Size = UDim2.fromScale(0.9, 0.25),
		},
		Cards = {
			{
				ProductId = "credits_50000",
				Pictures = {
					{
						Image = SHOP_IMAGES["currency-pile.png"],
						Position = UDim2.new(0.5, 0, 0.45, 3),
						Size = UDim2.fromScale(0.7, 0.55),
					},
				},
				Button = CREDIT_BUTTON_AREA,
			},
			{
				ProductId = "credits_25000",
				Pictures = {
					{
						Image = SHOP_IMAGES["currency-bills-and-coins.png"],
						Position = UDim2.new(0.5131, 0, 0.4465, 3),
						Size = UDim2.fromScale(0.6229, 0.4618),
					},
				},
				Button = CREDIT_BUTTON_AREA,
			},
			{
				ProductId = "credits_10000",
				Pictures = {
					{
						Image = SHOP_IMAGES["currency-bill-stack.png"],
						Position = UDim2.fromScale(0.5, 0.4826),
						Size = UDim2.fromScale(0.45, 0.375),
					},
				},
				Button = CREDIT_BUTTON_AREA,
			},
			{
				ProductId = "credits_5000",
				-- the same bill twice, fanned out
				Pictures = {
					{
						Image = SHOP_IMAGES["currency-bill.png"],
						Position = UDim2.new(0.5, 0, 0.4229, 3),
						Size = UDim2.fromScale(0.5, 0.25),
						Rotation = -30,
					},
					{
						Image = SHOP_IMAGES["currency-bill.png"],
						Position = UDim2.fromScale(0.5, 0.5229),
						Size = UDim2.fromScale(0.5, 0.25),
						Rotation = -10,
					},
				},
				Button = CREDIT_BUTTON_AREA,
			},
			{
				ProductId = "credits_2500",
				Pictures = {
					{
						Image = SHOP_IMAGES["currency-coin-stack.png"],
						Position = CREDIT_BUTTON_AREA.Position,
						Size = CREDIT_BUTTON_AREA.Size,
					},
				},
				Button = CREDIT_BUTTON_AREA,
			},
			{
				ProductId = "credits_500",
				Pictures = {
					{
						Image = SHOP_IMAGES["currency-coins.png"],
						Position = UDim2.new(0.5, 0, 0.4226, 3),
						Size = UDim2.fromScale(0.5, 0.25),
					},
				},
				-- the smallest pile is the only one whose button is as small as its picture
				Button = {
					Position = UDim2.new(0.5, 0, 0.4226, 3),
					Size = UDim2.fromScale(0.5, 0.25),
				},
			},
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
do
	-- a card is drawn under the id of its product, so the second of a pair would take the place of the first
	local productIds: { [string]: true } = {}
	for _, tabInfo in TABS do
		assert(Types.TabInfo(tabInfo))
		for _, cardInfo in tabInfo.Cards do
			assert(not productIds[cardInfo.ProductId], `"{cardInfo.ProductId}" has two cards in the shop`)
			productIds[cardInfo.ProductId] = true
		end
	end
end
TableUtil.deepFreeze(TABS)

return {
	TABS = TABS,
}
