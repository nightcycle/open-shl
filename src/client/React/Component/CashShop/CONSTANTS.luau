--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- every number in here is the old place's, in scale of the panel: it had no anchor, no layout + nothing sized in
-- pixels
-- a row is as wide as the panel, six of them fill it from the top with a thin gap between two
local ROW_SIZE = UDim2.fromScale(1, 0.15)
local ROW_STEP = 0.17
local MAX_ROWS = 6
-- what a row sells is written over its left, what's pressed for it is on its right
local LABEL_SIZE = UDim2.fromScale(0.7, 1)
local BUTTON_POSITION = UDim2.fromScale(0.7, 0)
local BUTTON_SIZE = UDim2.fromScale(0.3, 1)
-- a green no other screen has, with black on it
local BUTTON_COLOR = Color3.new(0, 1, 0)
local BUTTON_TEXT_COLOR = Color3.new(0, 0, 0)
local BUTTON_TEXT = "BUY"
-- Variables
-- References
-- Private Functions
-- Class
return table.freeze({
	ROW_SIZE = ROW_SIZE,
	ROW_STEP = ROW_STEP,
	MAX_ROWS = MAX_ROWS,
	LABEL_SIZE = LABEL_SIZE,
	BUTTON_POSITION = BUTTON_POSITION,
	BUTTON_SIZE = BUTTON_SIZE,
	BUTTON_COLOR = BUTTON_COLOR,
	BUTTON_TEXT_COLOR = BUTTON_TEXT_COLOR,
	BUTTON_TEXT = BUTTON_TEXT,
})
