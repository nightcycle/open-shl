--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AcrobaticsDefinition = require("@game/ReplicatedStorage/Shared/Definition/Acrobatics")
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
-- "Drag" is the box let go of somewhere else
export type ActionInfo =
	{
		Type: "Play",
		MoveId: string,
	}
	| {
		Type: "Fix",
	}
	| {
		Type: "Drag",
		Position: UDim2,
	}
export type Properties = RobloxComponents.FrameProperties & {
	-- where the box was left the last time it was let go of, where the old place put it without
	BoxPosition: UDim2?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local FIX_ID = AcrobaticsDefinition.FIX_ID
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the panel of flips of the first game: a see-through blue box at the right edge with a button for every move, two
-- to a row, + one that puts a body back on its feet. the whole of it is the player's to drag somewhere else
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)

	local children: { [string]: React.ReactNode } = {
		-- the box follows whatever takes hold of it. where it's let go of is told, so it can be put back there
		Drag = e("UIDragDetector", {
			[React.Event.DragEnd] = function(detector: Instance)
				local box = detector.Parent
				if box and box:IsA("GuiObject") then
					props.OnAction({
						Type = "Drag",
						Position = box.Position,
					})
				end
			end,
		}),
	}
	for index, id in AcrobaticsDefinition.ORDER do
		local moveRes = AcrobaticsDefinition.get(id)
		children[id] = e("TextButton", {
			FontFace = style.Fonts.Body,
			Position = CONSTANTS.getButtonPosition(index),
			Size = CONSTANTS.BUTTON_SIZE,
			Style = CONSTANTS.BUTTON_STYLE,
			Text = if moveRes.IsOk then moveRes.Value.Name else CONSTANTS.FIX_TEXT,
			TextColor3 = style.Palette.Text,
			TextScaled = true,
			[React.Event.Activated] = function()
				if id == FIX_ID then
					props.OnAction({
						Type = "Fix",
					})
				else
					props.OnAction({
						Type = "Play",
						MoveId = id,
					})
				end
			end,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Box = e("Frame", {
				Active = true,
				BackgroundColor3 = style.Palette.Field,
				BackgroundTransparency = CONSTANTS.BOX_TRANSPARENCY,
				-- the edge the engine gives a box was never taken off it
				BorderColor3 = style.Border.Color3,
				BorderSizePixel = style.Border.SizePixel,
				Position = props.BoxPosition or CONSTANTS.BOX.Position,
				Size = CONSTANTS.BOX.Size,
			}, children),
		}
	))
end
