--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local ConfigurePanel = require("@self/ConfigurePanel")
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local ItemList = require("@self/ItemList")
-- Hooks
-- Contexts
-- Types
local Appearance = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type Item = Appearance.Item
export type ActionInfo =
	{
		Type: "OnUpdate",
		Item: Item,
	}
	| {
		Type: "Exit",
	}

export type Properties = Frame.Properties & {
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(
		Frame({
			BackgroundTransparency = 1,
		}),
		props,
		{
			ConfigurePanel = e(ConfigurePanel, {
				AnchorPoint = Vector2.new(1, 0.5),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.95, 0.5),
				Size = UDim2.fromScale(0.3, 0.8),
			}),
			ItemList = e(ItemList, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.05, 0.5),
				Size = UDim2.fromScale(0.3, 0.8),
				Rows = {
					{
						Rarity = "Common",
						Items = {
							"ABC",
							"123"
						}
					}
				},
				OnClick = function(item)
					print(`selected: "{item}"`)
				end,
			}, {}),
			BackButton = e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.3,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 0.9),
				Size = UDim2.fromScale(0.15, 0.1),
				Text = "Exit",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			TurnChar = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.225, 0.05),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				Right = e("TextButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Modal = true,
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromScale(0.2, 0.2),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = ">",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeColor3 = Color3.new(1, 1, 1),
				}),

				Left = e("TextButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Modal = true,
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(0.2, 0.2),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = "<",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeColor3 = Color3.new(1, 1, 1),
				}),
			}),
		}
	)
end
