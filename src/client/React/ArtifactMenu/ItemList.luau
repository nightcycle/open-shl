--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local ScrollingFrame = require("@game/ReplicatedStorage/Generated/React/Component/ScrollingFrame")
local UIListLayout = require("@game/ReplicatedStorage/Generated/React/Component/UIListLayout")
-- Hooks
-- Contexts
-- Types
export type Properties = ScrollingFrame.Properties & {
	Rows: {
		{
			Rarity: string,
			Items: { string },
		}
	},
	OnClick: (string) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local out: { [string]: React.ReactNode } = {}
	local rowIndex = 0
	for rarityOrder, rarityEntry in props.Rows do
		rowIndex += 1
		out[`{rarityOrder}`] = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new(
				"rbxasset://fonts/families/SourceSansPro.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Size = UDim2.new(1, -15, 0.0095, 0),
			Text = rarityEntry.Rarity,
			LayoutOrder = rowIndex,
			TextColor3 = Color3.fromRGB(255, 213, 0),
			TextScaled = true,
		})
		for i, item in rarityEntry.Items do
			rowIndex += 1
			out[`{rarityOrder}-{i}`] = e("TextButton", {
				BackgroundColor3 = Color3.new(),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				LayoutOrder = rowIndex,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Size = UDim2.new(1, -15, 0.008, 0),
				Text = item,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = 0,
				[React.Event.Activated] = function()
					props.OnClick(item)
				end,
			})
		end
	end
	return e(
		ScrollingFrame({
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.3,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			CanvasSize = UDim2.fromScale(0, 7.5),
			ScrollingDirection = Enum.ScrollingDirection.Y,
		} :: ScrollingFrame.Properties),
		props,
		{
			UIListLayout = e(
				"UIListLayout",
				{
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(),
				} :: UIListLayout.Properties
			),
			Rows = e(React.Fragment, {}, out),
		}
	)
end
