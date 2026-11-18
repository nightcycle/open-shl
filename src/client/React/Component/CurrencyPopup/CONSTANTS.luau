--!strict
-- Services
-- Packages
-- Modules
local Audio = require("@game/ReplicatedStorage/Generated/Audio")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
export type CurrencyInfo = {
	Text: string,
	TextColor3: Color3,
	TextStrokeColor3: Color3,
	Volume: number,
}
-- Constants
local CURRENCIES: { [PseudoEnum.Currency]: CurrencyInfo } = table.freeze({
	Credits = table.freeze({
		Text = "Credits",
		TextColor3 = Color3.fromRGB(0, 118, 0),
		TextStrokeColor3 = Color3.fromRGB(0, 255, 0),
		Volume = 0.5,
	}),
	Gems = table.freeze({
		Text = "Gems",
		TextColor3 = Color3.fromRGB(229, 0, 0),
		TextStrokeColor3 = Color3.new(1, 1, 1),
		Volume = 1,
	}),
})
-- Variables
-- References
-- Private Functions
-- Class
return {
	CURRENCIES = CURRENCIES,
	SOUND_ID = Audio.ui["currency.ogg"],
}
