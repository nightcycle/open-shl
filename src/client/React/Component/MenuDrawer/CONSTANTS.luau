--!strict
-- Services
-- Packages
-- Modules
-- Types
-- a part of the hud, in scale of whatever holds it
export type Box = {
	Position: UDim2,
	Size: UDim2,
}
-- Constants
-- every number in here is the old place's, in scale of the screen or of the box that holds it: it had no anchor, no
-- layout + nothing sized in pixels
-- the drawer is a screen of its own that's moved as a whole: 0.4 of the width further left only its button shows
local OPEN_POSITION = UDim2.fromScale(0, 0)
local SHUT_POSITION = UDim2.fromScale(-0.4, 0)
-- the blue box the five lines are in, it fills the lower left of the screen
local BODY: Box = table.freeze({
	Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.fromScale(0.4, 0.4),
})
local BODY_TRANSPARENCY = 0.5
-- what opens + shuts it rides on the right edge of the body
local MENU: Box = table.freeze({
	Position = UDim2.fromScale(0.4, 0.5),
	Size = UDim2.fromScale(0.08, 0.09),
})
local MENU_TRANSPARENCY = 0.3
local MENU_TEXT = "Menu"
-- a line is nearly as wide as the body, where each starts is how far down the body it is
local LINE_SIZE = UDim2.fromScale(0.95, 0.15)
local LINE_X = 0.025
local SWAP_LINE_Y = 0.05
local MODE_LINE_Y = 0.25
local MASK_LINE_Y = 0.45
local RESET_LINE_Y = 0.65
local SAVES_LINE_Y = 0.825
-- the first three lines say what they're for on the left + have what's pressed on the right
local LABEL_SIZE = UDim2.fromScale(0.67, 1)
local BUTTON: Box = table.freeze({
	Position = UDim2.fromScale(0.7, 0),
	Size = UDim2.fromScale(0.3, 1),
})
local BUTTON_TRANSPARENCY = 0.5
local RESET: Box = table.freeze({
	Position = UDim2.fromScale(0.0255, 0),
	Size = UDim2.fromScale(0.3, 1),
})
local NEW_CHARACTER: Box = table.freeze({
	Position = UDim2.fromScale(0.35, 0),
	Size = UDim2.fromScale(0.65, 1),
})
-- the two that take the avatar away are a red the game shows through a little
local RESET_TRANSPARENCY = 0.2
local SAVES: Box = table.freeze({
	Position = UDim2.fromScale(0.2, 0),
	Size = UDim2.fromScale(0.6, 1),
})
-- the one dark text of the drawer, it's neither the black of the shop button nor what the engine writes in
local SAVES_TEXT_COLOR = Color3.fromRGB(40, 40, 40)
-- the box under the ticker the balance stands on
local BALANCE: Box = table.freeze({
	Position = UDim2.fromScale(0.4, 0.065),
	Size = UDim2.fromScale(0.2, 0.07),
})
-- where the panel of the shop opens. its button hangs off the top of that, right under the balance
local SHOP: Box = table.freeze({
	Position = UDim2.fromScale(0.3, 0.2),
	Size = UDim2.fromScale(0.4, 0.6),
})
local SHOP_BUTTON: Box = table.freeze({
	Position = UDim2.fromScale(0.35, -0.1),
	Size = UDim2.fromScale(0.3, 0.1),
})
local SHOP_TEXT_COLOR = Color3.new(0, 0, 0)
-- what can't be used is half gone, box + text: the way the old place drew a button it had no use for yet
local DEAD_FADE = 0.5
-- Variables
-- References
-- Private Functions
-- Class
return table.freeze({
	OPEN_POSITION = OPEN_POSITION,
	SHUT_POSITION = SHUT_POSITION,
	BODY = BODY,
	BODY_TRANSPARENCY = BODY_TRANSPARENCY,
	MENU = MENU,
	MENU_TRANSPARENCY = MENU_TRANSPARENCY,
	MENU_TEXT = MENU_TEXT,
	LINE_SIZE = LINE_SIZE,
	LINE_X = LINE_X,
	SWAP_LINE_Y = SWAP_LINE_Y,
	MODE_LINE_Y = MODE_LINE_Y,
	MASK_LINE_Y = MASK_LINE_Y,
	RESET_LINE_Y = RESET_LINE_Y,
	SAVES_LINE_Y = SAVES_LINE_Y,
	LABEL_SIZE = LABEL_SIZE,
	BUTTON = BUTTON,
	BUTTON_TRANSPARENCY = BUTTON_TRANSPARENCY,
	RESET = RESET,
	NEW_CHARACTER = NEW_CHARACTER,
	RESET_TRANSPARENCY = RESET_TRANSPARENCY,
	SAVES = SAVES,
	SAVES_TEXT_COLOR = SAVES_TEXT_COLOR,
	BALANCE = BALANCE,
	SHOP = SHOP,
	SHOP_BUTTON = SHOP_BUTTON,
	SHOP_TEXT_COLOR = SHOP_TEXT_COLOR,
	DEAD_FADE = DEAD_FADE,
	-- what the switch is called: until there's an avatar, as the secret identity + as the hero. the old place had the
	-- last two the other way around, each named the switch that was just made
	SWAP_TEXT = "Change Character Mode",
	SWAP_TO_HERO_TEXT = "Change into Hero",
	SWAP_TO_SECRET_TEXT = "Change Back",
	SWAP_BUTTON_TEXT = "CHANGE",
	-- the mode is asked as a question the button answers
	MODE_TEXT = "RP Mode:",
	PEACEFUL_TEXT = "TRUE",
	FIGHTING_TEXT = "FALSE",
	MASK_TEXT = "Mask:",
	MASK_BUTTON_TEXT = "UN-MASK",
	RESET_TEXT = "RESET",
	NEW_CHARACTER_TEXT = "NEW CHARACTER",
	SAVES_TEXT = "My Saved Suits",
	-- the button of the shop says what the next press of it does
	SHOP_TEXT = "BUY MORE",
	SHOP_OPEN_TEXT = "EXIT",
})
