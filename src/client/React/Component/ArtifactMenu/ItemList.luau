--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ScrollingFrame = require("@game/ReplicatedStorage/Generated/React/Component/ScrollingFrame")
local UIListLayout = require("@game/ReplicatedStorage/Generated/React/Component/UIListLayout")
-- Hooks
-- Contexts
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
export type RarityItemGroup = {
	Rarity: PseudoEnum.Rarity,
	ItemDefinitions: { ItemDefinition },
}
export type Properties = ScrollingFrame.Properties & {
	SelectedItemDefinition: ItemDefinition?,
	ItemGroups: { RarityItemGroup },
	OnClick: (ItemDefinition) -> (),
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
	local categoryIndex = 0
	for rarityOrder, rarityEntry in props.ItemGroups do
		rowIndex += 1
		categoryIndex += 1
		out[`{rarityOrder}`] = e("TextLabel", {
			BackgroundTransparency = 1,
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			FontFace = Font.new(
				"rbxasset://fonts/families/SourceSansPro.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Size = UDim2.new(1, -15, 0.0095 * 14, 0),
			Text = rarityEntry.Rarity == PseudoEnum.Rarity.VeryCommon and "Very Common" or rarityEntry.Rarity,
			LayoutOrder = rowIndex,
			TextColor3 = Color3.fromRGB(255, 213, 0),
			TextScaled = true,
		})
		for i, itemDef in rarityEntry.ItemDefinitions do
			local itemDefIndex = ItemAppearanceDefinition.getIndex(itemDef.Id)
			local name = itemDef.Name or itemDefIndex.IsOk and itemDefIndex.Value.Key or nil
			if name == nil then
				continue
			end
			rowIndex += 1
			local isSelected = props.SelectedItemDefinition and props.SelectedItemDefinition.Id == itemDef.Id or false
			out[`{rarityOrder}-{i}`] = e("TextButton", {
				BackgroundColor3 = isSelected and Color3.new(1, 1, 1) or Color3.new(),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BackgroundTransparency = isSelected and 0.7 or 0,
				BorderSizePixel = 0,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				AutoButtonColor = true,
				LayoutOrder = rowIndex,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Size = UDim2.new(1, -15, 0.008 * 14, 0),
				Text = name,
				TextColor3 = isSelected and Color3.new() or Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = isSelected and 0 or 1,
				[React.Event.Activated] = function()
					props.OnClick(itemDef)
				end,
			})
		end
	end
	return e(ScrollingFrame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.3,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			CanvasSize = UDim2.fromScale(0, categoryIndex * 0.015 + rowIndex * 0.06),
			ScrollingDirection = Enum.ScrollingDirection.Y,
		},
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
	))
end
