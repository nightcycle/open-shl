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
-- the picture is a square canvas with the panel drawn across its middle, so the frame that carries it is taller than
-- the panel that's seen. the places + sizes are the ones the old place had, in scale of that frame
return {
	-- half as wide as the screen + as tall as wide, in the middle of it
	MENU_IMAGE = Image["shl-3"].ui.info["panel.png"],
	MENU_POSITION = UDim2.fromScale(0.4998, 0.5),
	MENU_SIZE = UDim2.fromScale(0.5, 0.5),

	-- the art has a title, three heads + ten rows drawn into it. a tag covers each of the four words
	TITLE_POSITION = UDim2.fromScale(0.5, 0.289),
	TITLE_SIZE = UDim2.fromScale(0.35, 0.0325),
	HEAD_COLOR = Color3.fromRGB(209, 209, 209),
	USER_NAME_HEAD_POSITION = UDim2.fromScale(0.1524, 0.325),
	USER_NAME_HEAD_SIZE = UDim2.fromScale(0.2193, 0.0325),
	BOUNTY_HEAD_POSITION = UDim2.fromScale(0.5, 0.325),
	BOUNTY_HEAD_SIZE = UDim2.fromScale(0.35, 0.0325),
	NAME_HEAD_POSITION = UDim2.fromScale(0.8491, 0.325),
	NAME_HEAD_SIZE = UDim2.fromScale(0.1969, 0.0325),

	-- a sheet over the rows of the art, the list has rows of its own
	COVER_POSITION = UDim2.fromScale(0.011, 0.342),
	COVER_SIZE = UDim2.fromScale(0.978, 0.395),

	-- the list hangs from its bottom edge. its canvas is twice as tall as it is, whoever is on it
	LIST_POSITION = UDim2.fromScale(0.5, 0.734),
	LIST_SIZE = UDim2.fromScale(0.958, 0.385),
	LIST_CANVAS_SIZE = UDim2.fromScale(0, 2),
	LIST_PADDING = UDim.new(0.003, 0),
	-- the bar its old place scrolled it with is a picture of that universe nobody else can load, this is the one of
	-- its shop
	SCROLL_BAR_IMAGE = Image["shl-3"].ui.shop["scroll-bar.png"],
	-- how thick the scroll bar is in scale of the height of the panel + in pixels until that's known
	SCROLL_BAR_SCALE = 0.05 * 0.27,
	SCROLL_BAR_THICKNESS = 13,
	-- the track that's drawn down the left of the panel
	TRACK_IMAGE = Image["shl-3"].ui.common["sidebar-thin.png"],
	TRACK_POSITION = UDim2.fromScale(-0.3926, 0.3245),
	TRACK_SIZE = UDim2.new(0.7326, 14, 0.4347, 0),

	-- a row is a strip of three cells. it's small on purpose: a full server fits on the list without a scroll
	ROW_SIZE = UDim2.fromScale(1, 0.019),
	ROW_PADDING = UDim.new(0.006, 0),
	USER_NAME_CELL_SIZE = UDim2.fromScale(0.261, 1),
	BOUNTY_CELL_SIZE = UDim2.fromScale(0.465, 1),
	NAME_CELL_SIZE = UDim2.fromScale(0.26, 1),
	ROW_TEXT_COLOR = Color3.fromRGB(190, 190, 190),

	-- the exit of the look hangs on the right edge of the frame, where the art has its corner. the old one was put by
	-- a point 12 pixels under its top, this one is put by its middle
	EXIT_POSITION = UDim2.new(1, 0, 0.25, 8),
}
