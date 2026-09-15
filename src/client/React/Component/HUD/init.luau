--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local ImageButton = require("@game/ReplicatedStorage/Generated/React/Component/ImageButton")
local StatBars = require("@self/StatBars")
local UIListLayout = require("@game/ReplicatedStorage/Generated/React/Component/UIListLayout")
-- Types
export type Properties = Frame.Properties & {
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
			} :: ImageButton.Properties
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
			} :: ImageButton.Properties
		)
	end
	return e(
		Frame({
			BackgroundTransparency = 1,
			Active = false,
		} :: Frame.Properties),
		props,
		{
			Bars = e(StatBars, {}),
			Left = e(
				"Frame",
				{
					Size = UDim2.fromScale(0.08, 0.75 + 0.08 - 0.45),
					Position = UDim2.fromScale(0.04, 0.45),
					BackgroundTransparency = 1,
					Active = false,
				} :: Frame.Properties,
				{
					UIListLayout = e(
						"UIListLayout",
						{
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0.02, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						} :: UIListLayout.Properties
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
					BackgroundTransparency = 1,
					Active = false,
				} :: Frame.Properties,
				{
					UIListLayout = e(
						"UIListLayout",
						{
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0.02, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						} :: UIListLayout.Properties
					),
					Buttons = e(React.Fragment, {}, rightButtons),
				}
			),
		}
	)
end
