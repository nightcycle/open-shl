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
local BuildTypes = require("./Types")
type Category = BuildTypes.Category
export type Properties = RobloxComponents.ScrollingFrameProperties & {
	Categories: { Category },
	SelectedCategory: Category?,
	OnClick: (Category) -> (),
}
-- Constants
-- how tall a row is + how far it is from one to the next, in scale of the canvas
local ROW_SIZE = 0.1
local ROW_PITCH = 0.11
local SCROLL_BAR_INSET = 15
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local rows: { [string]: React.ReactNode } = {}
	for i, category: Category in props.Categories do
		local isSelected = props.SelectedCategory == category
		rows[category] = e(
			"TextButton",
			{
				BackgroundColor3 = isSelected and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(159, 159, 159),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0, ROW_PITCH * (i - 1)),
				Size = UDim2.new(1, -SCROLL_BAR_INSET, ROW_SIZE, 0),
				Text = category,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				[React.Event.Activated] = function()
					props.OnClick(category)
				end,
			} :: RobloxComponents.TextButtonProperties
		)
	end
	return e(RobloxComponents.ScrollingFrame(
		{
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.4,
			BorderColor3 = Color3.new(1, 1, 1),
			CanvasSize = UDim2.fromScale(0, 1),
			ScrollBarThickness = 14,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		},
		props,
		{
			Rows = e(React.Fragment, {}, rows),
		}
	))
end
