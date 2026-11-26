--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
export type Properties = RobloxComponents.FrameProperties & {
	-- the line that's up, nil while the strip is parked under the screen
	Text: string?,
}
-- Constants
local SHOWN_POSITION = UDim2.fromScale(0.5, 0.795)
local PARKED_POSITION = UDim2.fromScale(0.5, 1.25)
-- both of the height of the screen: 756 by 32 on one that's 1080 tall
local STRIP_SIZE = UDim2.fromScale(0.7, 0.03)
local SLIDE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut)
-- a shade off the grey every other text of the look is in
local TEXT_COLOR3 = Color3.fromRGB(116, 116, 116)
-- the one thing of the look that has a border of its own, the art of every other box has its frame drawn in
local BORDER_THICKNESS = 5
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- one line from the town, on a strip that comes up from under the screen + goes back down. how long a line is up
-- for is whoever mounts it to say
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local isShown = props.Text ~= nil
	-- the line is still read on its way down
	local textRef = React.useRef(props.Text or "")
	if props.Text then
		textRef.current = props.Text
	end

	local stripRef: { current: TextLabel? } = React.useRef(nil :: TextLabel?)
	-- the strip is only told where it starts out, from there on it slides to where it belongs
	local initialPositionRef = React.useRef(isShown and SHOWN_POSITION or PARKED_POSITION)
	useTween(stripRef, SLIDE_TWEEN_INFO, {
		Position = isShown and SHOWN_POSITION or PARKED_POSITION,
	}, { isShown })

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Strip = e("TextLabel", {
				ref = stripRef,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = style.Palette.Field,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Body,
				Position = initialPositionRef.current,
				Size = STRIP_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = textRef.current,
				TextColor3 = TEXT_COLOR3,
				TextScaled = true,
				TextWrapped = true,
			}, {
				UIStroke = e("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = style.Palette.Accent,
					LineJoinMode = Enum.LineJoinMode.Miter,
					Thickness = BORDER_THICKNESS,
				}),
			}),
		}
	))
end
