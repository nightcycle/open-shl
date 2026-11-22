--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- every picture is a square canvas with what's seen drawn across its middle, so the frame that carries one is larger
-- than the button or the panel it shows. the places + sizes are the ones the old place opened its menu to
return {
	-- the list + the offer only open once the buttons did
	PANEL_DELAY = 0.5,

	-- the list of slots, left of the stage. its art is stretched to the height of the screen
	LIST_IMAGE = Image["shl-3"].ui["suit-manager"]["slot-free.png"],
	LIST_POSITION = UDim2.fromScale(0.15, 0.5),
	LIST_SIZE = UDim2.fromScale(0.25, 0.9),
	LIST_PADDING = UDim.new(0.015, 0),

	-- a slot is a bar in the list, the art is 5.75 rows tall so the bar that's drawn on it covers the row
	ROW_IMAGE = Image["shl-3"].ui.common["button-template-3.png"],
	ROW_SIZE = UDim2.fromScale(0.4, 0.0525),
	ROW_ART_POSITION = UDim2.fromScale(0, -2.3571),
	ROW_ART_SIZE = UDim2.fromScale(1, 5.7462),
	ROW_TEXT_SIZE = UDim2.fromScale(0.9, 0.6),
	ROW_COLOR = Color3.new(1, 1, 1),
	ROW_TEXT_COLOR = Color3.fromRGB(122, 122, 122),

	-- select + edit sit side by side at the bottom, a gap of 2% of the screen between them. both are as wide as a
	-- fifth of it + a quarter as tall as wide
	SELECT_IMAGE = Image["shl-3"].ui["suit-manager"]["select.png"],
	SELECT_POSITION = UDim2.new(0.49, 0, 1, -20),
	EDIT_IMAGE = Image["shl-3"].ui["suit-manager"]["edit.png"],
	EDIT_POSITION = UDim2.new(0.51, 0, 1, -20),
	BUTTON_SIZE = UDim2.fromScale(0.2, 0.05),
	-- the word is drawn into the art as well, the tag covers it
	TAG_POSITION = UDim2.fromScale(0.5, 0.2038),
	TAG_SIZE = UDim2.fromScale(0.6, 0.4077),
	-- a line over the edit button
	NOTE_SIZE = UDim2.fromOffset(200, 30),
	NOTE_COLOR = Color3.new(1, 1, 1),

	-- the pass that doubles the slots, right of the stage. its art is stretched as well
	OFFER_IMAGE = Image["shl-3"].ui["suit-manager"]["slot-paid.png"],
	OFFER_POSITION = UDim2.fromScale(0.95, 0.44),
	OFFER_SIZE = UDim2.fromScale(0.25, 0.308),
	OFFER_ICON_IMAGE = Image["shl-3"].ui.shop["gamepass-double-slots.png"],
	OFFER_ICON_POSITION = UDim2.fromScale(0.5, 0.51),
	OFFER_ICON_SIZE = UDim2.fromScale(0.65, 0.65),
	OFFER_ICON_COLOR = Color3.new(1, 1, 1),
	OFFER_BUTTON_POSITION = UDim2.fromScale(0.5, 0.9707),
	OFFER_BUTTON_SIZE = UDim2.fromScale(0.6, 0.6),
	OFFER_TEXT_POSITION = UDim2.fromScale(0.5, 0.495),
	OFFER_TEXT_SIZE = UDim2.fromScale(0.957, 0.098),

	-- the way out is the exit of the look, in the corner nothing else of the menu reaches: as far off the top + the
	-- right edge as a button of the hud is off its own
	EXIT_POSITION = UDim2.new(1, -30, 0, 30),

	-- the camera looks at a point this far over the spot a plain body stands on. it gives way to how tall a body is
	-- the way the one of the editor does, which keeps the feet where they are in the picture: backing off + looking
	-- higher up alone had the feet of the tallest body end up behind the two buttons. at half of what a body is
	-- taller the tallest head of hair on it is out of the top of the picture, so this one makes up for a little more
	CAMERA_TARGET_OFFSET = Vector3.new(0, 3.1, 0),
	CAMERA_FOLLOW = 0.6,
	-- how long it takes to get to a new framing, at a steady pace
	CAMERA_DURATION = 0.75,
}
