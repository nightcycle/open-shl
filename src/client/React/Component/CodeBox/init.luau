--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
export type ActionInfo =
	{
		Type: "Change", -- what's in the box is another text now
		Text: string,
	}
	| {
		Type: "Submit", -- the box was left with something in it
		Text: string,
	}
	| {
		Type: "Focus", -- the box was clicked into
	}
export type Properties = RobloxComponents.FrameProperties & {
	-- what's in the box, whoever mounts it keeps it
	Text: string,
	-- read in an empty box in place of what it usually says there: why the last code paid nothing
	Notice: string?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local PLACEHOLDER_TEXT = "Type Code Here"
local PLACEHOLDER_COLOR3 = Color3.fromRGB(178, 178, 178)
-- the picture is a square of this much of the width of the screen, the box that's typed into sits on the field
-- that's drawn in it
local ART_SIZE = UDim2.fromScale(0.128, 0.128)
local ART_POSITION = UDim2.fromScale(0.073, 0.679)
-- both of the height of the screen: 162 by 43 on one that's 1080 tall
local BOX_SIZE = UDim2.fromScale(0.15, 0.04)
local BOX_POSITION = UDim2.fromScale(0.041, 0.685)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the box of the legacy place a code is typed into, on the left edge under the buttons of its hud. it's sent as the
-- box is left, by enter or by a click anywhere else
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Art = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(Image["shl-3"].ui.codes["text-box.png"]),
				Position = ART_POSITION,
				Size = ART_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),
			Box = e("TextBox", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClearTextOnFocus = true,
				FontFace = style.Fonts.Body,
				PlaceholderColor3 = PLACEHOLDER_COLOR3,
				PlaceholderText = props.Notice or PLACEHOLDER_TEXT,
				Position = BOX_POSITION,
				Size = BOX_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = props.Text,
				TextColor3 = Color3.new(0, 0, 0),
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,
				[React.Change.Text] = function(box: TextBox)
					if box.Text ~= props.Text then
						props.OnAction({
							Type = "Change",
							Text = box.Text,
						})
					end
				end,
				[React.Event.Focused] = function()
					props.OnAction({
						Type = "Focus",
					})
				end,
				[React.Event.FocusLost] = function(box: TextBox)
					if box.Text ~= "" then
						props.OnAction({
							Type = "Submit",
							Text = box.Text,
						})
					end
				end,
			}),
		}
	))
end
