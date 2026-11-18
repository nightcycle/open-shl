--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ConfigurePanel = require("@self/ConfigurePanel")
local ItemList = require("@self/ItemList")
local Scene = require("@self/Scene")
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local ItemDefSelection =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Selection/AppearanceItemDefinition")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
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
		Type: "SetTagVisibility",
		Tag: HiddenTag,
		IsVisible: boolean,
	}
	| {
		Type: "Exit",
	}

export type Properties = RobloxComponents.FrameProperties & {
	OnAction: (ActionInfo) -> (),
}
-- Constants
local SLIDE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local selectedItemDef: ItemDefinition? = React.useContext(ItemDefSelection)
	local itemDefinitions = React.useMemo(function(): { ItemDefinition }
		return ItemAppearanceDefinition.list("costume", "artifacts")
	end, {})
	local groups = React.useMemo(function(): { ItemList.RarityItemGroup }
		local rarityGroups: { [PseudoEnum.Rarity]: { ItemDefinition } } = {}
		for _, itemDef in itemDefinitions do
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
	end, { itemDefinitions })

	local controlsRef: { current: Frame? } = React.useRef(nil :: Frame?)
	useTween(controlsRef, SLIDE_TWEEN_INFO, {
		Position = UDim2.new(),
	}, {})

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- the scene reaches up over the top bar, so the backdrop does too
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),
			Scene = e(Scene, {}),
			Controls = e(
				"Frame",
				{
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.fromScale(1, 1),
					ref = controlsRef,
				} :: RobloxComponents.FrameProperties,
				{
					ConfigurePanel = selectedItemDef and e(
						ConfigurePanel,
						{
							SelectedItemDefinition = selectedItemDef,
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
							SelectedItemDefinition = selectedItemDef,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromScale(0.05, 0.5),
							Size = UDim2.fromScale(0.3, 0.8),
							ItemGroups = groups,
							OnClick = function(itemDef: ItemDefinition)
								if itemDef == selectedItemDef then
									props.OnAction({
										Type = "SelectItem",
									})
								else
									props.OnAction({
										Type = "SelectItem",
										ItemDefinition = itemDef,
									})
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
			),
		}
	))
end
