--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local StatBars = require("@self/StatBars")
-- Types
export type Properties = RobloxComponents.FrameProperties & {
	OnClick: (PseudoEnum.MenuId) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local leftButtons: { [string]: React.ReactNode } = {}
	for i, buttonInfo in CONSTANTS.BUTTONS.LEFT do
		leftButtons[`{buttonInfo.MenuId}`] = e(
			"ImageButton",
			{
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = i,
				BorderSizePixel = 1,
				BackgroundColor3 = buttonInfo.BackgroundColor3,
				ImageContent = Content.fromUri(buttonInfo.Image),
				[React.Event.Activated] = function()
					props.OnClick(buttonInfo.MenuId)
				end,
			} :: RobloxComponents.ImageButtonProperties
		)
	end
	local rightButtons: { [string]: React.ReactNode } = {}
	for i, buttonInfo in CONSTANTS.BUTTONS.RIGHT do
		rightButtons[`{buttonInfo.MenuId}`] = e(
			"ImageButton",
			{
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = i,
				BorderSizePixel = 1,
				BackgroundColor3 = buttonInfo.BackgroundColor3,
				ImageContent = Content.fromUri(buttonInfo.Image),
				[React.Event.Activated] = function()
					props.OnClick(buttonInfo.MenuId)
				end,
			} :: RobloxComponents.ImageButtonProperties
		)
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Bars = e(StatBars, {}),
			Left = e(
				"Frame",
				{
					Size = UDim2.fromScale(0.08, 0.75 + 0.08 - 0.45),
					Position = UDim2.fromScale(0.04, 0.45),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,
					Active = false,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e(
						"UIListLayout",
						{
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0.02, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						} :: RobloxComponents.UIListLayoutProperties
					),
					Buttons = e(React.Fragment, {}, leftButtons),
				}
			),
			Right = e(
				"Frame",
				{
					AnchorPoint = Vector2.new(1, 0),
					Size = UDim2.fromScale(0.08, 0.75 + 0.08 - 0.45),
					Position = UDim2.fromScale(1 - 0.04, 0.45),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,
					Active = false,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e(
						"UIListLayout",
						{
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0.02, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						} :: RobloxComponents.UIListLayoutProperties
					),
					Buttons = e(React.Fragment, {}, rightButtons),
				}
			),
		}
	))
end
