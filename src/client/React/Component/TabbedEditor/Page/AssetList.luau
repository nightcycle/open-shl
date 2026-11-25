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
export type RowInfo = {
	Key: string,
	Text: string,
	IsSelected: boolean,
	Price: number?, -- what it costs while it has to be bought, nil for what's the player's or anybody's
	OnClick: () -> (),
}
export type Properties = RobloxComponents.ScrollingFrameProperties & {
	Rows: { RowInfo },
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a pill with a name on it: the pill is tinted while what it names is worn or picked, + green with a price on it
-- while it has to be bought
local function row(props: {
	LayoutOrder: number,
	Row: RowInfo,
})
	local style = React.useContext(StyleContext)
	local isSelected = props.Row.IsSelected
	local price = props.Row.Price
	local artColor = if isSelected
		then style.Palette.Accent
		elseif price then CONSTANTS.UNOWNED_ROW_COLOR
		else Color3.new(1, 1, 1)
	return e("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(CONSTANTS.ROW_WIDTH, 0, 0, CONSTANTS.ROW_HEIGHT),
	}, {
		Art = e("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = CONSTANTS.ROW_ART,
			ImageColor3 = artColor,
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromScale(1, CONSTANTS.ROW_ART_HEIGHT),
		}),
		TextButton = e("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = CONSTANTS.ROW_TEXT_SIZE,
			Text = props.Row.Text,
			TextColor3 = if isSelected then style.Palette.TextOnAccent else CONSTANTS.ROW_TEXT_COLOR,
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
			[React.Event.Activated] = props.Row.OnClick,
		}),
		PriceLabel = price and e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = CONSTANTS.PRICE_FONT,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = CONSTANTS.PRICE_SIZE,
			Text = `${price}`,
			TextColor3 = CONSTANTS.PRICE_TEXT_COLOR,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 4,
		}),
	})
end
-- Class
-- a list of rows that scrolls, its bar rides down the left side on a track that's drawn into the page
return function(props: Properties): React.ReactNode
	-- the bar is a share of how wide the list came out
	local barWidth, setBarWidth = React.useState(0)
	local rows: { [string]: React.ReactNode } = {}
	for index, rowInfo in props.Rows do
		rows[`Row-{rowInfo.Key}`] = e(row, {
			LayoutOrder = index,
			Row = rowInfo,
		})
	end
	return e(RobloxComponents.ScrollingFrame(
		{
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			BottomImage = "",
			CanvasSize = UDim2.fromOffset(0, #props.Rows * CONSTANTS.ROW_STEP),
			MidImage = CONSTANTS.LIST_SCROLL_BAR_IMAGE,
			ScrollBarThickness = barWidth,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			TopImage = "",
			VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
			[React.Change.AbsoluteSize] = function(scrollingFrame: ScrollingFrame)
				setBarWidth(math.round(scrollingFrame.AbsoluteSize.X * CONSTANTS.LIST_SCROLL_BAR_WIDTH))
			end,
		} :: RobloxComponents.ScrollingFrameProperties,
		props,
		{
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(CONSTANTS.LIST_PADDING, 0),
			}),
			Rows = e(React.Fragment, {}, rows),
		}
	))
end
