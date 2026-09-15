--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Hooks
-- Contexts
-- Types
export type Properties = Frame.Properties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(
		Frame({
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.3,
		} :: Frame.Properties),
		props,
		{

			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.fromScale(1, 0.1),
				Text = "Hat Name",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			Tier = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.1),
				Size = UDim2.fromScale(1, 0.05),
				Text = "Legendary",
				TextColor3 = Color3.fromRGB(255, 213, 0),
				TextScaled = true,
			}),

			Hood = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.3),
				Size = UDim2.fromScale(0.5, 0.08),
				Text = "Hood",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			Mask = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.2),
				Size = UDim2.fromScale(0.5, 0.08),
				Text = "Mask",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			Mouth = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.5, 0.08),
				Text = "Mouth Cover",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			MaskButt = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(75, 151, 75),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.6, 0.2),
				Size = UDim2.fromScale(0.3, 0.08),
				Text = "On",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			HairButt = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(75, 151, 75),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.6, 0.4),
				Size = UDim2.fromScale(0.3, 0.08),
				Text = "On",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			Hair = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.4),
				Size = UDim2.fromScale(0.5, 0.08),
				Text = "Hair",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			HoodButt = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(75, 151, 75),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.6, 0.3),
				Size = UDim2.fromScale(0.3, 0.08),
				Text = "On",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			MouthButt = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(75, 151, 75),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.6, 0.5),
				Size = UDim2.fromScale(0.3, 0.08),
				Text = "On",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			Wear = e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 170, 0),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 0.85),
				Size = UDim2.fromScale(0.5, 0.12),
				Text = "Wear",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
		}
	)
end
