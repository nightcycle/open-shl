--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ConfigurePanel = require("@self/ConfigurePanel")
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local ItemList = require("@self/ItemList")
local Scene = require("@self/Scene")
-- Hooks
-- Contexts
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
export type HiddenTag = AppearanceType.HiddenTag
export type ActionInfo =
	{
		Type: "AddItem",
		ItemDefinition: ItemDefinition,
	}
	| {
		Type: "RemoveItem",
		ItemDefinition: ItemDefinition,
	}
	| {
		Type: "SetTagVisibility",
		Tag: HiddenTag,
		IsVisible: boolean,
	}
	| {
		Type: "Exit",
	}

export type Properties = Frame.Properties & {
	ItemDefinitions: { ItemDefinition },
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local selectedItem: ItemDefinition?, setSelectedItem: (ItemDefinition?) -> () =
		React.useState(nil :: ItemDefinition?)
	local groups = React.useMemo(function(): { ItemList.RarityItemGroup }
		local rarityGroups: { [PseudoEnum.Rarity]: { ItemDefinition } } = {}
		for i, itemDef in props.ItemDefinitions do
			if itemDef.Rarity then
				local group = rarityGroups[itemDef.Rarity] or {}
				rarityGroups[itemDef.Rarity] = group

				table.insert(group, itemDef)
			else
				warn(`no rarity for "{itemDef.Id}"`)
			end
		end
		local out: { ItemList.RarityItemGroup } = {}
		for rarity, defs in rarityGroups do
			table.insert(
				out,
				table.freeze({
					Rarity = rarity :: PseudoEnum.Rarity,
					ItemDefinitions = table.freeze(defs),
				})
			)
		end

		table.sort(out, function(a: ItemList.RarityItemGroup, b: ItemList.RarityItemGroup)
			local aValue = PseudoEnum.getValueFromEnumItem("Rarity", (a.Rarity or "VeryCommon") :: PseudoEnum.Rarity)
			local bValue = PseudoEnum.getValueFromEnumItem("Rarity", (b.Rarity or "VeryCommon") :: PseudoEnum.Rarity)
			return aValue < bValue
		end)
		table.freeze(out)
		return out
	end, { props.ItemDefinitions })

	return e(Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Scene = e(Scene, {}),
			ConfigurePanel = selectedItem and e(
				ConfigurePanel,
				{
					SelectedItemDefinition = selectedItem,
					AnchorPoint = Vector2.new(1, 0.5),
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = UDim2.fromScale(0.95, 0.5),
					Size = UDim2.fromScale(0.3, 0.8),
					SetVisibility = function(tag: HiddenTag, toVisibility: boolean)
						props.OnAction({
							Type = "SetTagVisibility",
							Tag = tag,
							IsVisible = toVisibility,
						})
					end,
					OnRemove = function(itemDef: ItemDefinition)
						props.OnAction({
							Type = "RemoveItem",
							ItemDefinition = itemDef,
						})
					end,
					OnWear = function(itemDef: ItemDefinition)
						props.OnAction({
							Type = "AddItem",
							ItemDefinition = itemDef,
						})
					end,
				} :: ConfigurePanel.Properties
			),
			ItemList = e(
				ItemList,
				{
					SelectedItemDefinition = selectedItem,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0.05, 0.5),
					Size = UDim2.fromScale(0.3, 0.8),
					ItemGroups = groups,
					OnClick = function(item: ItemDefinition)
						if item == selectedItem then
							setSelectedItem(nil)
						else
							setSelectedItem(item)
						end
					end,
				} :: ItemList.Properties
			),
			Exit = e("TextButton", {
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
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Exit",
					})
				end,
			}),
		}
	))
end
