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
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type Area = StyleTypes.Area
export type ButtonInfo = {
	Id: string,
	Text: string,
}
export type ActionInfo = {
	Type: "Press",
	Id: string,
}
export type Properties = RobloxComponents.FrameProperties & {
	Title: string,
	Text: string,
	-- one or two of them. a single one is the wide one in the middle, of two the first is on the left
	Buttons: { ButtonInfo },
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- everything is laid out in scale of the square the panel is drawn on, which is larger than the panel that's seen
local TITLE_POSITION = UDim2.fromScale(0.5, 0.26)
local TITLE_SIZE = UDim2.fromScale(0.5, 0.08)
-- how far down the row of buttons is, by its middle
local BUTTON_HEIGHT = 0.725
local BUTTON_SIZE = UDim2.fromScale(0.25, 0.08)
local WIDE_BUTTON_SIZE = UDim2.fromScale(0.45, 0.08)
-- how far off the middle each of two buttons starts
local BUTTON_GAP = 0.015
local MAX_BUTTONS = 2
-- a look without a picture has its box behind all of the above + the text between them
local FRAME_AREA: Area = table.freeze({
	Position = UDim2.fromScale(0.05, 0.19),
	Size = UDim2.fromScale(0.9, 0.61),
})
local FRAME_BODY: Area = table.freeze({
	Position = UDim2.fromScale(0.0759, 0.3675),
	Size = UDim2.fromScale(0.8498, 0.2838),
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a question or a word to the player with a button or two under it, on the panel of the look
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local palette = style.Palette
	local panel = style.Panel
	local border = style.Border
	local buttonImage = style.Widgets.Dialog.ButtonImage
	assert(
		#props.Buttons >= 1 and #props.Buttons <= MAX_BUTTONS,
		`a dialog has 1 to {MAX_BUTTONS} buttons, not {#props.Buttons}`
	)
	local isWide = #props.Buttons == 1

	local buttons: { [string]: React.ReactNode } = {}
	for index, buttonInfo in props.Buttons do
		local isLeft = index == 1
		buttons[`Button-{buttonInfo.Id}`] = e(
			"ImageButton",
			{
				AnchorPoint = if isWide then Vector2.new(0.5, 0.5) else Vector2.new(isLeft and 1 or 0, 0.5),
				-- the button itself isn't seen, it's the bar behind what it says
				BackgroundTransparency = 1,
				Position = if isWide
					then UDim2.fromScale(0.5, BUTTON_HEIGHT)
					else UDim2.fromScale(0.5 + (isLeft and -BUTTON_GAP or BUTTON_GAP), BUTTON_HEIGHT),
				Size = if isWide then WIDE_BUTTON_SIZE else BUTTON_SIZE,
				ZIndex = 2,
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Press",
						Id = buttonInfo.Id,
					})
				end,
			} :: RobloxComponents.ImageButtonProperties,
			{
				-- the bar is in the middle band of a square picture, so that's as tall as the button is wide
				Bar = if buttonImage
					then e("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageContent = Content.fromUri(buttonImage),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
					})
					else e("Frame", {
						BackgroundColor3 = palette.FieldAlt,
						BorderColor3 = border.Color3,
						BorderSizePixel = border.SizePixel,
						Size = UDim2.fromScale(1, 1),
					}),
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Body,
					Size = UDim2.fromScale(1, 1),
					Text = buttonInfo.Text,
					TextColor3 = palette.Text,
					TextSize = style.TextSizes.Button,
					TextWrapped = true,
					ZIndex = 2,
				}),
			}
		)
	end

	local body: Area = if panel.Type == "Image" then panel.Body else FRAME_BODY
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Panel = if panel.Type == "Image"
				then e("ImageLabel", {
					BackgroundTransparency = 1,
					ImageColor3 = panel.ImageColor3,
					ImageContent = Content.fromUri(panel.Image),
					ScaleType = panel.ScaleType,
					SliceCenter = panel.SliceCenter,
					Size = UDim2.fromScale(1, 1),
				})
				else e("Frame", {
					BackgroundColor3 = panel.BackgroundColor3,
					BackgroundTransparency = panel.BackgroundTransparency,
					BorderColor3 = panel.BorderColor3,
					BorderSizePixel = panel.BorderSizePixel,
					Position = FRAME_AREA.Position,
					Size = FRAME_AREA.Size,
				}),
			-- a picture has its own heading drawn where this is, the tag covers it with what's really asked
			Title = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = palette.Accent,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Heading,
				Position = TITLE_POSITION,
				Size = TITLE_SIZE,
				Text = props.Title,
				TextColor3 = palette.TextOnAccent,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 2,
			}),
			Body = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Position = body.Position,
				Size = body.Size,
				Text = props.Text,
				TextColor3 = palette.Text,
				TextSize = style.TextSizes.Body,
				TextWrapped = true,
				ZIndex = 2,
			}),
			Buttons = e(React.Fragment, {}, buttons),
		}
	))
end
