--!strict
-- Services
-- Packages
-- Modules
-- Types
-- a part of the panel, in scale of whatever holds it
export type Box = {
	Position: UDim2,
	Size: UDim2,
}
-- Constants
-- every number in here is the old place's, which built the panel in a script: the box in scale of the screen, its
-- buttons in scale of the box. it had no anchor + no layout
-- the lower half of the right edge, a pixel up + to the left of where the scale puts it
local BOX: Box = table.freeze({
	Position = UDim2.new(0.85, -1, 0.5, -1),
	Size = UDim2.fromScale(0.15, 0.5),
})
local BOX_TRANSPARENCY = 0.5
-- two to a row, nine rows down the box
local BUTTON_SIZE = UDim2.fromScale(0.5, 0.1)
-- a button is the engine's own art, so no box of the game's is drawn under its name
local BUTTON_STYLE = Enum.ButtonStyle.RobloxRoundDefaultButton
-- the one button that's no move
local FIX_TEXT = "Fix Character"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.BOX = BOX
Module.BOX_TRANSPARENCY = BOX_TRANSPARENCY
Module.BUTTON_SIZE = BUTTON_SIZE
Module.BUTTON_STYLE = BUTTON_STYLE
Module.FIX_TEXT = FIX_TEXT

-- where the button of a number is put, counted from 1: the odd ones on the right, the even ones on the left, a row
-- further down with every second. the rows start a twentieth down the box + end as far above its bottom
Module.getButtonPosition = function(index: number): UDim2
	return UDim2.fromScale(index % 2 / 2, index / 20 + index % 2 / 20 - 0.05)
end

return table.freeze(Module)
