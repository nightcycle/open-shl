--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Components
-- Hooks
-- Contexts
-- Types
type BubbleSide = TutorialDefinition.BubbleSide
type Layout = {
	ANCHOR_POINT: Vector2,
	POSITION: UDim2,
	TEXT_ANCHOR_POINT: Vector2,
	TEXT_POSITION: UDim2,
	NEXT_POSITION: UDim2,
}
export type Properties = RobloxComponents.ImageLabelProperties & {
	BubbleSide: BubbleSide,
	Text: string,
	OnNext: (() -> ())?, -- left out while the captain waits on the player
}
-- Constants
local TEXT_FONT = Font.new("rbxasset://fonts/families/ComicNeueAngular.json")
local BUTTON_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local TEXT_COLOR = Color3.fromRGB(27, 42, 53)
local SIZE = UDim2.fromScale(1.8, 1) -- in scale of the square the captain sits in
local TEXT_SIZE = UDim2.fromScale(0.89, 0.4)
local NEXT_SIZE = UDim2.fromScale(0.3, 0.14)
local LAYOUTS: { [BubbleSide]: Layout } = table.freeze({
	Left = table.freeze({
		ANCHOR_POINT = Vector2.new(1, 1),
		POSITION = UDim2.fromScale(0.3, 0.3),
		TEXT_ANCHOR_POINT = Vector2.new(0, 0),
		TEXT_POSITION = UDim2.fromScale(0.02, 0.05),
		NEXT_POSITION = UDim2.fromScale(0.46, 0.56),
	}),
	Right = table.freeze({
		ANCHOR_POINT = Vector2.new(0, 1),
		POSITION = UDim2.fromScale(0.7, 0.3),
		TEXT_ANCHOR_POINT = Vector2.new(1, 0),
		TEXT_POSITION = UDim2.fromScale(0.98, 0.05),
		NEXT_POSITION = UDim2.fromScale(0.54, 0.56),
	}),
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local LAYOUT = LAYOUTS[props.BubbleSide]
	return e(RobloxComponents.ImageLabel(
		{
			AnchorPoint = LAYOUT.ANCHOR_POINT,
			Position = LAYOUT.POSITION,
			Size = SIZE,
			BackgroundTransparency = 1,
			ImageContent = Content.fromUri(TutorialDefinition.BUBBLE_IMAGES[props.BubbleSide]),
		},
		props,
		{
			TextLabel = e("TextLabel", {
				AnchorPoint = LAYOUT.TEXT_ANCHOR_POINT,
				Position = LAYOUT.TEXT_POSITION,
				Size = TEXT_SIZE,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				FontFace = TEXT_FONT,
				Text = props.Text,
				TextColor3 = TEXT_COLOR,
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			NextButton = props.OnNext and e(
				"TextButton",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = LAYOUT.NEXT_POSITION,
					Size = NEXT_SIZE,
					BackgroundColor3 = Color3.fromRGB(0, 194, 0),
					BorderColor3 = Color3.fromRGB(0, 255, 0),
					BorderSizePixel = 4,
					FontFace = BUTTON_FONT,
					Selectable = false,
					Text = "Next",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeTransparency = 0,
					TextWrapped = true,
					[React.Event.Activated] = props.OnNext,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
