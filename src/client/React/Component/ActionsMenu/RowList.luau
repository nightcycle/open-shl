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
export type RowInfo = {
	Id: string,
	Text: string,
	ButtonText: string,
	IsActive: boolean, -- used to determine if the button is red
	IsDisabled: boolean?,
	OnClick: () -> (),
}
export type Properties = RobloxComponents.ScrollingFrameProperties & {
	Rows: { RowInfo },
}
-- Constants
local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local IDLE_BUTTON_COLOR = Color3.fromRGB(9, 137, 207)
local ACTIVE_BUTTON_COLOR = Color3.fromRGB(196, 40, 28)
local DISABLED_TRANSPARENCY = 0.7
-- the share of the visible list a row takes up
local ROW_HEIGHT = 0.15
local SCROLL_BAR_INSET = 18
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function row(props: RobloxComponents.FrameProperties & {
	Text: string,
	ButtonText: string,
	IsActive: boolean,
	IsDisabled: boolean?,
	OnClick: () -> (),
})
	local isDisabled = props.IsDisabled == true
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = FONT,
				Size = UDim2.fromScale(0.65, 1),
				Text = props.Text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextTransparency = isDisabled and DISABLED_TRANSPARENCY or 0,
			}),
			Button = e(
				"TextButton",
				{
					BackgroundColor3 = props.IsActive and ACTIVE_BUTTON_COLOR or IDLE_BUTTON_COLOR,
					BackgroundTransparency = isDisabled and DISABLED_TRANSPARENCY or 0,
					BorderColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 2,
					FontFace = FONT,
					Position = UDim2.fromScale(0.675, 0.125),
					Size = UDim2.fromScale(0.325, 0.75),
					Text = props.ButtonText,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeColor3 = Color3.new(1, 1, 1),
					TextTransparency = isDisabled and DISABLED_TRANSPARENCY or 0,
					Active = not isDisabled,
					Selectable = not isDisabled,
					AutoButtonColor = not isDisabled,
					[React.Event.Activated] = not isDisabled and props.OnClick or nil,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
-- Class
return function(props: Properties)
	-- a row is sized as a share of the canvas, which is never shorter than the list itself
	local canvasHeight = math.max(1, #props.Rows * ROW_HEIGHT)
	local rows: { [string]: React.ReactNode } = {}
	for i, rowInfo in props.Rows do
		rows[rowInfo.Id] = e(row, {
			LayoutOrder = i,
			Size = UDim2.new(1, -SCROLL_BAR_INSET, ROW_HEIGHT / canvasHeight, 0),
			Text = rowInfo.Text,
			ButtonText = rowInfo.ButtonText,
			IsActive = rowInfo.IsActive,
			IsDisabled = rowInfo.IsDisabled,
			OnClick = rowInfo.OnClick,
		})
	end
	return e(RobloxComponents.ScrollingFrame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			CanvasSize = UDim2.fromScale(0, canvasHeight),
			-- rows that all fit leave nothing to scroll to, the canvas is held in place rather than made smaller
			ScrollingEnabled = canvasHeight > 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		},
		props,
		{
			UIListLayout = e(
				"UIListLayout",
				{
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(),
				} :: RobloxComponents.UIListLayoutProperties
			),
			Rows = e(React.Fragment, {}, rows),
		}
	))
end
