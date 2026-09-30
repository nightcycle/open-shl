--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Hooks
-- Contexts
local CharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Appearance")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
export type Properties = Frame.Properties & {
	SelectedItemDefinition: ItemDefinition,
	SetVisibility: (tag: AppearanceType.HiddenTag, toVisibility: boolean) -> (),
	OnWear: (itemDef: ItemDefinition) -> (),
	OnRemove: (itemDef: ItemDefinition) -> (),
}
-- Constants
local LABEL_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local BUTTON_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local GREEN_BUTTON_COLOR = Color3.fromRGB(75, 151, 75)
local RED_BUTTON_COLOR = Color3.fromRGB(151, 75, 75)

-- Variables
-- References
-- Private Functions
local e = React.createElement
function buttonGroup(props: {
	HiddenTag: AppearanceType.HiddenTag,
	Text: string?,
	PositionY: UDim,
	SetVisibility: (tag: AppearanceType.HiddenTag, toVisibility: boolean) -> (),
})
	local characterAppearance: CharacterAppearanceContext.Appearance = React.useContext(CharacterAppearanceContext)
	local hasItem = React.useMemo(function(): boolean
		for i, item in characterAppearance.Items do
			local definition = ItemAppearanceDefinition.get(item.DefinitionId)
			if definition.IsOk then
				if table.find(definition.Value.Tags, props.HiddenTag) then
					return true
				end
			else
				warn(definition.Value)
			end
		end
		return false
	end, { characterAppearance.Items })

	local isVisible = table.find(characterAppearance.HiddenTags, props.HiddenTag) == nil
	return hasItem
		and e(React.Fragment, {}, {
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = LABEL_FONT,
				Position = UDim2.new(UDim.new(0, 0), props.PositionY),
				Size = UDim2.fromScale(0.5, 0.08),
				Text = props.Text or props.HiddenTag,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			Button = e("TextButton", {
				BackgroundColor3 = not isVisible and RED_BUTTON_COLOR or GREEN_BUTTON_COLOR,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = BUTTON_FONT,
				Position = UDim2.new(UDim.new(0.6, 0), props.PositionY),
				Size = UDim2.fromScale(0.3, 0.08),
				Text = not isVisible and "Off" or "On",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					props.SetVisibility(props.HiddenTag, not isVisible)
				end,
			}),
		})
end
-- Class
return function(props: Properties)
	local itemIndexRes = React.useMemo(function()
		return ItemAppearanceDefinition.getIndex(props.SelectedItemDefinition.Id)
	end, { props.SelectedItemDefinition.Id })

	return e(Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.3,
		},
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
				Text = props.SelectedItemDefinition and props.SelectedItemDefinition.Name
					or itemIndexRes and itemIndexRes.IsOk and itemIndexRes.Value.Key
					or "...",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			Tier = props.SelectedItemDefinition.Rarity and e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.1),
				Size = UDim2.fromScale(1, 0.05),
				Text = props.SelectedItemDefinition.Rarity == PseudoEnum.Rarity.VeryCommon and "Very Common"
					or props.SelectedItemDefinition.Rarity,
				TextColor3 = Color3.fromRGB(255, 213, 0),
				TextScaled = true,
			}),

			VisibilityToggles = e(React.Fragment, {}, {
				Mask = e(buttonGroup, {
					HiddenTag = "Mask" :: AppearanceType.HiddenTag,
					PositionY = UDim.new(0.2, 0),
					SetVisibility = props.SetVisibility,
				}),
				Hood = e(buttonGroup, {
					HiddenTag = "Hood" :: AppearanceType.HiddenTag,
					PositionY = UDim.new(0.3, 0),
					SetVisibility = props.SetVisibility,
				}),
				Hair = e(buttonGroup, {
					HiddenTag = "Hair" :: AppearanceType.HiddenTag,
					PositionY = UDim.new(0.4, 0),
					SetVisibility = props.SetVisibility,
				}),
				MouthCover = e(buttonGroup, {
					HiddenTag = "MouthCover" :: AppearanceType.HiddenTag,
					PositionY = UDim.new(0.5, 0),
					SetVisibility = props.SetVisibility,
				}),
			}),

			Wear = e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(0, 170, 0),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = BUTTON_FONT,
				Position = UDim2.fromScale(0.5, 0.85),
				Size = UDim2.fromScale(0.5, 0.12),
				Text = "Wear",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
		}
	))
end
