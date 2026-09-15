--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	return e(React.Fragment, {}, {
		Energy = e("Frame", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.new(0.35, 0, 0.01, 25),
			Size = UDim2.new(0.3, 0, 0, 20),
		}, {
			EnergyBar = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(26, 167, 255),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.01, 0.06),
				Size = UDim2.fromScale(0.98, 0.88),
			}),

			TextLabel = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Position = UDim2.fromScale(0, 0.06),
				Size = UDim2.fromScale(1, 0.88),
				Text = "ENERGY",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				ZIndex = 2,
			}),
		}),

		Health = e("Frame", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.35, 0.01),
			Size = UDim2.new(0.3, 0, 0, 20),
		}, {
			HealthBar = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 170, 0),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.01, 0.06),
				Size = UDim2.fromScale(0.98, 0.88),
			}),

			TextLabel = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Position = UDim2.fromScale(0, 0.06),
				Size = UDim2.fromScale(1, 0.88),
				Text = "HEALTH",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				ZIndex = 2,
			}),
		}),
		EnergyWarning = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.02, 45),
			Size = UDim2.new(0.3, 0, 0, 20),
			Text = "Not Enough Energy",
			TextColor3 = Color3.fromRGB(255, 204, 0),
			TextScaled = true,
			TextStrokeColor3 = Color3.fromRGB(255, 0, 0),
			TextStrokeTransparency = 0.5,
		}),
	})
end
