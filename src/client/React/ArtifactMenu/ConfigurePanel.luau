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
	SetVisibility: (id: string, toVisibility: boolean) -> (),
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
-- Class
return function(props: Properties)
	local itemIndexRes = React.useMemo(function()
		return ItemAppearanceDefinition.getIndex(props.SelectedItemDefinition.Id)
	end, { props.SelectedItemDefinition.Id })

	local characterAppearance: CharacterAppearanceContext.Appearance = React.useContext(CharacterAppearanceContext)
	local mask = React.useMemo(function(): Item?
		for i, item in characterAppearance.Items do
			local defIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
			if defIndexRes.IsOk then
				if defIndexRes.Value.Group == "costume" and defIndexRes.Value.Category == "masks" then
					return item
				end
			else
				warn(defIndexRes.Value)
			end
		end
		return
	end, { characterAppearance.Items })
	local isMaskVisible = table.find(characterAppearance.HiddenTags, "Mask") == nil
	local hood = React.useMemo(function(): Item?
		for i, item in characterAppearance.Items do
			local defIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
			if defIndexRes.IsOk then
				if defIndexRes.Value.Group == "costume" and defIndexRes.Value.Category == "hoods" then
					return item
				end
			else
				warn(defIndexRes.Value)
			end
		end
		return
	end, { characterAppearance.Items })
	local isHoodVisible = table.find(characterAppearance.HiddenTags, "Hood") == nil

	local hair = React.useMemo(function(): Item?
		for i, item in characterAppearance.Items do
			local defIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
			if defIndexRes.IsOk then
				if defIndexRes.Value.Group == "cosmetics" and defIndexRes.Value.Category == "hair" then
					return item
				end
			else
				warn(defIndexRes.Value)
			end
		end
		return
	end, { characterAppearance.Items })
	local isHairVisible = table.find(characterAppearance.HiddenTags, "Hair") == nil

	local mouthCover = React.useMemo(function(): Item?
		for i, item in characterAppearance.Items do
			local defIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
			if defIndexRes.IsOk then
				if defIndexRes.Value.Group == "costume" and defIndexRes.Value.Category == "mouth-covers" then
					return item
				end
			else
				warn(defIndexRes.Value)
			end
		end
		return
	end, { characterAppearance.Items })
	local isMouthCoverVisible = table.find(characterAppearance.HiddenTags, "MouthCover") == nil

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

			Hood = hood and e(React.Fragment, {}, {
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0, 0.3),
					Size = UDim2.fromScale(0.5, 0.08),
					Text = "Hood",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
				}),

				Button = e("TextButton", {
					BackgroundColor3 = not isHoodVisible and RED_BUTTON_COLOR or GREEN_BUTTON_COLOR,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0.6, 0.3),
					Size = UDim2.fromScale(0.3, 0.08),
					Text = not isHoodVisible and "Off" or "On",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
			}),
			Mask = mask and e(React.Fragment, {}, {
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0, 0.2),
					Size = UDim2.fromScale(0.5, 0.08),
					Text = "Mask",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
				}),

				Button = e("TextButton", {
					BackgroundColor3 = not isMaskVisible and RED_BUTTON_COLOR or GREEN_BUTTON_COLOR,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0.6, 0.2),
					Size = UDim2.fromScale(0.3, 0.08),
					Text = not isMaskVisible and "Off" or "On",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
			}),
			MouthCover = mouthCover and e(React.Fragment, {}, {
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(0.5, 0.08),
					Text = not isHoodVisible and "Off" or "Mouth Cover",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
				}),

				Button = e("TextButton", {
					BackgroundColor3 = not isMouthCoverVisible and RED_BUTTON_COLOR or GREEN_BUTTON_COLOR,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0.6, 0.5),
					Size = UDim2.fromScale(0.3, 0.08),
					Text = not isMouthCoverVisible and "Off" or "On",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
			}),
			Hair = hair and e(React.Fragment, {}, {
				Button = e("TextButton", {
					BackgroundColor3 = not isHairVisible and RED_BUTTON_COLOR or GREEN_BUTTON_COLOR,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0.6, 0.4),
					Size = UDim2.fromScale(0.3, 0.08),
					Text = not isHairVisible and "Off" or "On",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),

				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0, 0.4),
					Size = UDim2.fromScale(0.5, 0.08),
					Text = "Hair",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
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
	)
end
