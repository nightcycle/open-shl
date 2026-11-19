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
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/RobuxShop/Types")
type Area = Types.Area
type Picture = Types.Picture
export type Properties = RobloxComponents.FrameProperties & {
	Title: string,
	Tile: string,
	Caption: Area,
	Pictures: { Picture },
	Button: Area,
	-- what the sticker in its corner says, a card without one has no sticker
	StickerText: string?,
	-- a card that's faded can't be pressed
	IsFaded: boolean?,
	OnClick: () -> (),
}
-- Constants
-- the strip a caption is written on: its art is a square as wide as the caption, hung so the strip is behind the text
local LABEL_IMAGE = Image["shl-3"].ui.common["label.png"]
local LABEL_POSITION = UDim2.fromScale(0.5, 0.75)
-- the text of a caption was never given a color, so it had the one the engine starts a text on
local CAPTION_COLOR = Color3.fromRGB(27, 42, 53)
-- a sticker is stuck on askew in the top right corner
local STICKER_POSITION = UDim2.fromScale(0.6582, 0.1504)
local STICKER_SIZE = UDim2.fromScale(0.528, 0.1325)
local STICKER_ROTATION = 15
local STICKER_TEXT_COLOR = Color3.new()
-- how much of its pictures is seen through once it can't be pressed
local FADE = 0.5
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a square tile with what's sold in its middle + what it's called under it. only the middle is a button
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local isFaded = props.IsFaded == true

	local pictures: { [string]: React.ReactNode } = {}
	for i, picture in props.Pictures do
		pictures[`Picture{i}`] = e(
			"ImageLabel",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ImageContent = Content.fromUri(picture.Image),
				ImageTransparency = isFaded and FADE or 0,
				Position = picture.Position,
				Rotation = picture.Rotation,
				Size = picture.Size,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 2,
			} :: RobloxComponents.ImageLabelProperties
		)
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Tile = e(
				"ImageLabel",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ImageContent = Content.fromUri(props.Tile),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 1,
				} :: RobloxComponents.ImageLabelProperties
			),
			Pictures = e(React.Fragment, {}, pictures),
			Sticker = props.StickerText and e(
				"TextLabel",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = style.Palette.Warning,
					BorderSizePixel = 0,
					FontFace = style.Fonts.Heading,
					Position = STICKER_POSITION,
					Rotation = STICKER_ROTATION,
					Size = STICKER_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = props.StickerText,
					TextColor3 = STICKER_TEXT_COLOR,
					TextSize = style.TextSizes.Note,
					ZIndex = 3,
				} :: RobloxComponents.TextLabelProperties
			),
			Caption = e(
				"Frame",
				{
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Position = props.Caption.Position,
					Size = props.Caption.Size,
					ZIndex = 4,
				} :: RobloxComponents.FrameProperties,
				{
					Art = e(
						"ImageLabel",
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							ImageContent = Content.fromUri(LABEL_IMAGE),
							Position = LABEL_POSITION,
							Size = UDim2.fromScale(1, 1),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							ZIndex = 1,
						} :: RobloxComponents.ImageLabelProperties
					),
					Title = e(
						"TextLabel",
						{
							BackgroundTransparency = 1,
							FontFace = style.Fonts.Heading,
							Size = UDim2.fromScale(1, 1),
							Text = props.Title,
							TextColor3 = CAPTION_COLOR,
							TextSize = style.TextSizes.Note,
							ZIndex = 2,
						} :: RobloxComponents.TextLabelProperties
					),
				}
			),
			-- nothing is drawn for it, it lies over the pictures
			Button = e(
				"ImageButton",
				{
					Active = not isFaded,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = props.Button.Position,
					Selectable = not isFaded,
					Size = props.Button.Size,
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					ZIndex = 5,
					[React.Event.Activated] = not isFaded and function()
						props.OnClick()
					end or nil,
				} :: RobloxComponents.ImageButtonProperties
			),
		}
	))
end
