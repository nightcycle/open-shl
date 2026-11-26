--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
-- Contexts
-- Types
export type Properties = RobloxComponents.FrameProperties & {
	Caption: string, -- what's counted, the name of the tool
	Count: number, -- how much of it is left
	Max: number, -- what it's at when it's full
	Text: string?, -- shown in place of the count
}
-- Constants
-- every number in here is the old place's: the one thing it put on the screen in pixels. 70 in from the right edge
-- + 10 up from the bottom
local BAR_POSITION = UDim2.new(1, -270, 1, -70)
local BAR_SIZE = UDim2.fromOffset(200, 60)
-- the dark see-through panel with round corners the engine draws
local BAR_STYLE = Enum.FrameStyle.RobloxRound
local FILL_COLOR = Color3.fromRGB(127, 127, 127)
-- the fill leaves the top fifth of the bar to the two labels
local FILL_TOP = 0.2
local LABEL_FONT = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local LABEL_TEXT_SIZE = 14
local LABEL_COLOR = Color3.new(1, 1, 1)
-- over the fill
local LABEL_Z_INDEX = 3
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a label of the old bar had no size: its text hangs off the corner it's put in
local function label(props: { [any]: any }): React.ReactNode
	return e("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = LABEL_FONT,
		Position = props.Position,
		Size = UDim2.fromOffset(0, 0),
		Text = props.Text,
		TextColor3 = LABEL_COLOR,
		TextSize = LABEL_TEXT_SIZE,
		TextXAlignment = props.TextXAlignment,
		ZIndex = LABEL_Z_INDEX,
	})
end
-- Class
-- the ammo bar of the first game's machine gun, in the bottom right corner of whatever holds it: what the tool is
-- called, how much is left of how much + a fill that shrinks towards the right edge as it's used up
return function(props: Properties): React.ReactNode
	local ratio = math.clamp(props.Count / props.Max, 0, 1)

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Bar = e("Frame", {
				Position = BAR_POSITION,
				Size = BAR_SIZE,
				Style = BAR_STYLE,
			}, {
				-- the old one had a width below 0 to grow leftwards from the right edge
				Fill = e("Frame", {
					AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = FILL_COLOR,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(1, FILL_TOP),
					Size = UDim2.fromScale(ratio, 1 - FILL_TOP),
					Visible = ratio > 0,
				}),
				GunLabel = e(label, {
					Position = UDim2.fromScale(0, 0),
					Text = props.Caption,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				-- a count that's on its way up is never shown with a fraction
				AmmoLabel = e(label, {
					Position = UDim2.fromScale(1, 0),
					Text = props.Text or `{math.floor(props.Count)}/{props.Max}`,
					TextXAlignment = Enum.TextXAlignment.Right,
				}),
			}),
		}
	))
end
