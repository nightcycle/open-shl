--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ConfigurePanel = require("@self/ConfigurePanel")
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local ItemList = require("@self/ItemList")
-- Hooks
-- Contexts
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
export type ActionInfo =
	{
		Type: "OnUpdate",
		Item: ItemDefinition,
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
	local groups = React.useMemo(function(): { ItemList.RarityItemGroup }
		local rarityGroups: { [PseudoEnum.Rarity]: { string } } = {}
		for i, itemDef in props.ItemDefinitions do
			if itemDef.Rarity then
				local defIndexRes = ItemAppearanceDefinition.getItemDefinitionIndexFromId(itemDef.Id)
				if defIndexRes.IsOk then
					local group = rarityGroups[itemDef.Rarity] or {}
					rarityGroups[itemDef.Rarity] = group
					table.insert(group, defIndexRes.Value.Key)
				else
					warn(defIndexRes.Value)
				end
			else
				warn(`no rarity for "{itemDef.Id}"`)
			end
		end
		local out = {}
		for rarity, keys in rarityGroups do
			table.insert(
				out,
				table.freeze({
					Rarity = rarity,
					Keys = table.freeze(keys),
				})
			)
		end

		table.sort(out, function(a: ItemList.RarityItemGroup, b: ItemList.RarityItemGroup)
			local aValue = PseudoEnum.getValueFromEnumItem("Rarity", (a.Rarity or "VeryCommon") :: PseudoEnum.Rarity)
			local bValue = PseudoEnum.getValueFromEnumItem("Rarity", (b.Rarity or "VeryCommon") :: PseudoEnum.Rarity)
			return aValue > bValue
		end)
		table.freeze(out)
		return out
	end, { props.ItemDefinitions })

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
				ItemGroups = groups,
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
