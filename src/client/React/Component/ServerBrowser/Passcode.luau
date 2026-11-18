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
export type Properties = RobloxComponents.FrameProperties & {
	Code: string,
	OnChange: (code: string) -> (),
	OnSubmit: (code: string) -> (),
	OnBack: () -> (),
}
-- Constants
local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(RobloxComponents.Frame(
		{
			-- a click that lands on the cover isn't one on the list behind it
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		},
		props,
		{
			UIListLayout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			TextBox = e(
				"TextBox",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					FontFace = FONT,
					LayoutOrder = 1,
					PlaceholderColor3 = Color3.fromRGB(157, 157, 157),
					PlaceholderText = "Enter server specific passcode here",
					Size = UDim2.new(1, 0, 0, 30),
					Text = props.Code,
					TextColor3 = Color3.new(),
					TextSize = 20,
					[React.Change.Text] = function(textBox: TextBox)
						props.OnChange(textBox.Text)
					end :: any,
					[React.Event.FocusLost] = function(textBox: TextBox, isEnterPressed: boolean)
						if isEnterPressed then
							props.OnSubmit(textBox.Text)
						end
					end,
				} :: RobloxComponents.TextBoxProperties
			),
			Back = e(
				"TextButton",
				{
					BackgroundColor3 = Color3.fromRGB(151, 189, 212),
					FontFace = FONT,
					LayoutOrder = 2,
					Size = UDim2.fromOffset(150, 30),
					Text = "Back",
					TextColor3 = Color3.new(),
					TextSize = 14,
					[React.Event.Activated] = props.OnBack,
				} :: RobloxComponents.TextButtonProperties,
				{
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0.5, 0),
					}),
				}
			),
		}
	))
end
