--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- every number in here is the old place's. the log is a box nobody sees in the top left, right under the ticker: its
-- lines stand on its bottom edge + the button hangs under it
local LOG_POSITION = UDim2.fromScale(0, 0.075)
local LOG_SIZE = UDim2.fromScale(0.4, 0.35)
-- the newest line is the lowest, every one before it a line further up
local LINE_HEIGHT = 15
local LINE_COUNT = 12
local LINE_STROKE_COLOR = Color3.new(0, 0, 0)
-- in scale of the log
local MUTE_POSITION = UDim2.fromScale(0, 1)
local MUTE_SIZE = UDim2.fromScale(0.25, 0.15)
local MUTE_COLOR = Color3.fromRGB(0, 170, 255)
-- the button names who it would keep quiet: whoever made the other pick than the one who reads it
local MUTE_FIGHTING_TEXT = "MUTE PVP PLAYERS"
local MUTE_PEACEFUL_TEXT = "MUTE RP PLAYERS"
local MUTED_TEXT = "MUTED"
-- Variables
-- References
-- Private Functions
-- Class
return table.freeze({
	LOG_POSITION = LOG_POSITION,
	LOG_SIZE = LOG_SIZE,
	LINE_HEIGHT = LINE_HEIGHT,
	LINE_COUNT = LINE_COUNT,
	LINE_STROKE_COLOR = LINE_STROKE_COLOR,
	MUTE_POSITION = MUTE_POSITION,
	MUTE_SIZE = MUTE_SIZE,
	MUTE_COLOR = MUTE_COLOR,
	MUTE_FIGHTING_TEXT = MUTE_FIGHTING_TEXT,
	MUTE_PEACEFUL_TEXT = MUTE_PEACEFUL_TEXT,
	MUTED_TEXT = MUTED_TEXT,
})
