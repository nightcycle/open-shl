--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Explorer = require("@self/Explorer")
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local Properties = require("@self/Properties")
local Scene = require("@self/Scene")
-- Hooks
-- Contexts
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
export type HiddenTag = AppearanceType.HiddenTag
export type ActionInfo =
	{
		Type: "SelectItem",
		ItemDefinition: ItemDefinition?,
	}
	| {
		Type: "AddItem",
		ItemDefinition: ItemDefinition,
	}
	| {
		Type: "RemoveItem",
		ItemDefinition: ItemDefinition,
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
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Scene = e(Scene, {}),
		Explorer = e(Explorer, {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0, 0.025),
			Size = UDim2.fromScale(0.3, 0.54),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}),

		Properties = e(Properties, {
			Position = UDim2.fromScale(0.7, 0.025),
			Size = UDim2.fromScale(0.3, 0.54),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}),

		SwitchIdentity = e("Frame", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.375, 0.7),
			Size = UDim2.fromScale(0.25, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Button = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(255, 201, 37),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.new(1, -10, 1, -10),
				Text = "Swap Identities",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
			}),
		}),

		Exit = e("Frame", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.375, 0.025),
			Size = UDim2.fromScale(0.25, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Button = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(75, 115, 245),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.new(1, -10, 1, -10),
				Text = "Save and Exit",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
			}),
		}),
	})
end
