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
	if not fieldDefinition or fieldDefinition.Type ~= "Choose" then
		return
	end
	if not fieldCallback then
		return
	end
	local buttons: { [string]: React.ReactNode } = {}
	for i, choice in fieldDefinition.Choices do
		if choice.Type ~= "Text" then
			warn(`expected text for choice {choice.Value}`)
			continue
		end
		local width = 1 / #fieldDefinition.Choices
		local padPx = 7
		buttons[`Button{i}`] = e("TextButton", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(1, 1, 1),
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Position = UDim2.new((i - 1) * width, padPx * (i-0.5) / #fieldDefinition.Choices, 0, 0),
			Size = UDim2.new(width, -padPx, 1, 0),
			Text = choice.Text,
			TextSize = 14,
		})
	end
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			TextLabel = fieldDefinition.Description and e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Size = UDim2.fromScale(1, 0.3),
				Text = fieldDefinition.Description,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			Buttons = e("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.fromScale(1, 0.675),
			}, {
				Buttons = e(React.Fragment, {}, buttons),
			}),
		}
	))
end
