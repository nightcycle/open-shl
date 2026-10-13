--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Hooks
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
	local selected, setSelected = React.useState(false)
	if not fieldDefinition or fieldDefinition.Type ~= "Toggle" then
		return
	end
	if not fieldCallback then
		return
	end
	local isSelected = if props.IsSelected == nil then selected else props.IsSelected
	local function toggle()
		local nextSelected = not isSelected
		setSelected(nextSelected)
		fieldCallback(fieldDefinition, nextSelected)
	end
	local text = if isSelected then fieldDefinition.DisabledText or fieldDefinition.Text else fieldDefinition.Text
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.25),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			FilledButton = fieldDefinition.Style == "Filled" and e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 170, 0),
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
		}
	))
end
