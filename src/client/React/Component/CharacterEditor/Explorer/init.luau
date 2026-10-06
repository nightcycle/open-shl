--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local TextButton = require("@game/ReplicatedStorage/Generated/React/Component/TextButton")
-- Hooks
-- Contexts
-- Types
export type Properties = Frame.Properties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
function rowButton(props: TextButton.Properties)
	return e(TextButton({
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.new(1, 1, 1),
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		Modal = true,
		Size = UDim2.new(1, -15, 0.0375, 0),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextStrokeColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
	}, props))
end
-- Class
return function(props: Properties)
	return e(Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		} :: Frame.Properties,
		props,
		{
			ScrollingFrame = e("ScrollingFrame", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				Position = UDim2.new(0, 8, 0.2, 8),
				ScrollBarThickness = 15,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Size = UDim2.new(1, -16, 0.8, -16),
			}, {}),

			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Size = UDim2.fromScale(1, 0.1),
				Text = "Explorer",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			BackButton = e("TextButton", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0.3, 0.125),
				Size = UDim2.fromScale(0.4, 0.075),
				Text = "Exit",
				TextColor3 = Color3.fromRGB(255, 0, 0),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
			}),
		}
	))
end
