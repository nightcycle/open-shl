--!strict
-- Services
-- Packages
-- Modules
-- Types
local BuildTypes = require("./Types")
type CardState = BuildTypes.CardState
export type CardStateInfo = {
	CardColor3: Color3,
	ButtonColor3: Color3,
	TextStrokeTransparency: number,
}
export type SwatchInfo = {
	Name: string,
	PaletteKey: string,
}
-- Constants
local CARD_STATES: { [CardState]: CardStateInfo } = table.freeze({
	ForSale = table.freeze({
		CardColor3 = Color3.fromRGB(179, 179, 179),
		ButtonColor3 = Color3.fromRGB(85, 170, 0),
		TextStrokeTransparency = 1,
	}),
	Purchasing = table.freeze({
		CardColor3 = Color3.fromRGB(179, 179, 179),
		ButtonColor3 = Color3.fromRGB(255, 195, 97),
		TextStrokeTransparency = 0,
	}),
	Owned = table.freeze({
		CardColor3 = Color3.new(1, 1, 1),
		ButtonColor3 = Color3.fromRGB(160, 227, 255),
		TextStrokeTransparency = 0,
	}),
	Active = table.freeze({
		CardColor3 = Color3.new(1, 1, 1),
		ButtonColor3 = Color3.fromRGB(170, 0, 170),
		TextStrokeTransparency = 0,
	}),
})
-- Variables
-- References
-- Private Functions
-- Class
return {
	CARD_STATES = CARD_STATES,
	-- what a card turns for a moment when its purchase is turned down + for how long, in seconds
	REFUSAL_COLOR3 = Color3.fromRGB(255, 0, 0),
	REFUSAL_FLASH_DURATION = 0.4,
	-- the stripes of a theme card, top to bottom. the base has no water, the stripe shows all the same
	SWATCHES = {
		{
			Name = "Wall",
			PaletteKey = "Wall",
		} :: SwatchInfo,
		{
			Name = "Metal",
			PaletteKey = "Metal",
		},
		{
			Name = "Lighting",
			PaletteKey = "Lighting",
		},
		{
			Name = "Floor",
			PaletteKey = "Floor",
		},
		{
			Name = "Water",
			PaletteKey = "WaterRipple",
		},
	},
}
