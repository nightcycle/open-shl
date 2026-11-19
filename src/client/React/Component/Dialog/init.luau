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
-- a card has a row for its buttons, they're as tall as it is + this much of it wide. one of them stands in the middle
local CARD_BUTTON_SIZE = UDim2.fromScale(0.3, 1)
local CARD_WIDE_BUTTON_SIZE = UDim2.fromScale(0.4, 1)
local CARD_BUTTON_GAP = 0.025
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
-- a question or a word to the player with a button or two under it, on the panel of the look or on the card a look
-- has for it
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local palette = style.Palette
	local panel = style.Panel
	local border = style.Border
	local buttonImage = style.Widgets.Dialog.ButtonImage
	local card = style.Widgets.Dialog.Card
	assert(
		#props.Buttons >= 1 and #props.Buttons <= MAX_BUTTONS,
		`a dialog has 1 to {MAX_BUTTONS} buttons, not {#props.Buttons}`
	)
	local isWide = #props.Buttons == 1
	-- on a card the buttons are laid out in the row it has for them, not on the square of a picture
	local buttonHeight = if card then 0.5 else BUTTON_HEIGHT
	local buttonGap = if card then CARD_BUTTON_GAP else BUTTON_GAP
	local buttonSize = if card
		then (if isWide then CARD_WIDE_BUTTON_SIZE else CARD_BUTTON_SIZE)
		else (if isWide then WIDE_BUTTON_SIZE else BUTTON_SIZE)

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
					then UDim2.fromScale(0.5, buttonHeight)
					else UDim2.fromScale(0.5 + (isLeft and -buttonGap or buttonGap), buttonHeight),
				Size = buttonSize,
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
					elseif card then e("Frame", {
						BackgroundColor3 = palette.Field,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
					})
					else e("Frame", {
						BackgroundColor3 = palette.FieldAlt,
						BorderColor3 = border.Color3,
						BorderSizePixel = border.SizePixel,
						Size = UDim2.fromScale(1, 1),
					}),
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = if card then card.FontFace else style.Fonts.Body,
					Size = UDim2.fromScale(1, 1),
					Text = buttonInfo.Text,
					TextColor3 = palette.Text,
					-- whatever a card says fills the box it's in
					TextScaled = if card then true else nil,
					TextSize = if card then nil else style.TextSizes.Button,
					TextWrapped = true,
					ZIndex = 2,
				}),
			}
		)
	end

	if card then
		return e(RobloxComponents.Frame(
			{
				BackgroundTransparency = 1,
			},
			props,
			{
				Panel = e("Frame", {
					BackgroundColor3 = card.BackgroundColor3,
					BorderColor3 = card.BorderColor3,
					BorderSizePixel = card.BorderSizePixel,
					Size = UDim2.fromScale(1, 1),
				}),
				Title = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = card.FontFace,
					Position = card.Title.Position,
					Size = card.Title.Size,
					Text = props.Title,
					TextColor3 = card.TitleColor3,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
				}),
				Body = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = card.FontFace,
					Position = card.Body.Position,
					Size = card.Body.Size,
					Text = props.Text,
					TextColor3 = card.TextColor3,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
				}),
				Buttons = e("Frame", {
					BackgroundTransparency = 1,
					Position = card.Buttons.Position,
					Size = card.Buttons.Size,
					ZIndex = 2,
				}, buttons),
			}
		))
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
				elseif panel.Type == "Engine" then e("Frame", {
					Position = FRAME_AREA.Position,
					Size = FRAME_AREA.Size,
					Style = panel.Style,
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
