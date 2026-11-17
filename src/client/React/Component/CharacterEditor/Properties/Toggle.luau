--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
local useFieldValue =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFieldValue")
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
-- Types
local FieldTypes = require("./Types")
export type Properties = FieldTypes.FieldProperties
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local value = useFieldValue()
	if not fieldDefinition or fieldDefinition.Type ~= "Toggle" then
		return
	end
	if not fieldCallback or not value or value.Type ~= "Toggle" then
		return
	end
	local isSelected = if props.IsSelected == nil then value.IsSelected else props.IsSelected
	local function toggle()
		fieldCallback(fieldDefinition, {
			Type = "Toggle",
			IsSelected = not isSelected,
		})
	end
	local text = if isSelected then fieldDefinition.DisabledText or fieldDefinition.Text else fieldDefinition.Text
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.25),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			FilledButton = fieldDefinition.Style == "Filled" and e("TextButton", {
				BackgroundColor3 = isSelected and Color3.fromRGB(170, 0, 0) or Color3.fromRGB(0, 170, 0),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0.125, 0.25),
				Size = UDim2.fromScale(0.75, 0.5),
				Text = text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = toggle,
			}),
			OutlinedButton = fieldDefinition.Style == "Outline" and e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(107, 107, 107),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = isSelected and 3 or 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0.125, 0.25),
				Size = UDim2.fromScale(0.75, 0.5),
				Text = text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = toggle,
			}),
		}
	))
end
