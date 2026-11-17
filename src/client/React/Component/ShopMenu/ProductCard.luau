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
	Title: string,
	PriceText: string,
	CardColor3: Color3,
	IsOwned: boolean?,
	OnClick: () -> (),
}
-- Constants
local LABEL_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local isOwned = props.IsOwned == true
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.14),
		},
		props,
		{
			Purchase = e(
				"TextButton",
				{
					Active = not isOwned,
					AnchorPoint = Vector2.new(0, 0.5),
					AutoButtonColor = not isOwned,
					BackgroundColor3 = props.CardColor3,
					BackgroundTransparency = isOwned and 0.5 or 0,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.162, 0.5),
					Selectable = not isOwned,
					Size = UDim2.fromScale(0.675, 0.8),
					Text = "",
					[React.Event.Activated] = not isOwned and function()
						props.OnClick()
					end or nil,
				} :: RobloxComponents.TextButtonProperties,
				{
					Item = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = LABEL_FONT,
						Position = UDim2.fromScale(0.05, 0),
						Size = UDim2.fromScale(0.6, 0.7),
						Text = props.Title,
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
					}),
					Cost = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = LABEL_FONT,
						Position = UDim2.fromScale(0.65, 0.45),
						Size = UDim2.fromScale(0.3, 0.45),
						Text = props.PriceText,
						TextColor3 = Color3.fromRGB(0, 170, 0),
						TextScaled = true,
						TextStrokeTransparency = 0,
						TextXAlignment = Enum.TextXAlignment.Right,
						TextYAlignment = Enum.TextYAlignment.Bottom,
					}),
				}
			),
		}
	))
end
