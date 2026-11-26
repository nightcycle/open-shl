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
	-- the line that's up, nothing is drawn without
	Text: string?,
	TextColor3: Color3?,
}
-- Constants
-- all of the height of the screen: a box 50 tall, 100 down from the top of one that's 1080 tall, with letters of 24
local LINE_POSITION = UDim2.fromScale(0.5, 125 / 1080)
-- wide enough for a line three times as long as the one it was made for
local LINE_SIZE = UDim2.fromScale(600 / 1080, 24 / 1080)
local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local TEXT_COLOR3 = Color3.new(1, 0, 0)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- one bare line near the top of the screen, the way the old gear put its own up: no box, no way in or out. how long
-- it's up for is whoever mounts it to say
return function(props: Properties): React.ReactNode
	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Line = props.Text and e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = FONT,
				Position = LINE_POSITION,
				Size = LINE_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = props.Text,
				TextColor3 = props.TextColor3 or TEXT_COLOR3,
				TextScaled = true,
			}),
		}
	))
end
