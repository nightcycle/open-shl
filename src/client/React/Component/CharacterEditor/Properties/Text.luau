--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local TextBox = require("@game/ReplicatedStorage/Generated/React/Component/TextBox")
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
	if not fieldDefinition or fieldDefinition.Type ~= "Text" then
		return
	end
	if not fieldCallback then
		return
	end
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.25),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			TextBox = e(
				"TextBox",
				{
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.3,
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					MultiLine = true,
					PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
					Position = UDim2.fromScale(0.062, 0.125),
					Size = UDim2.fromScale(0.875, 0.5),
					Text = "",
					PlaceholderText = fieldDefinition.Description,
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
				} :: TextBox.Properties
			),

			Test = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 170, 255),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 2,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.25, 0.75),
				Size = UDim2.fromScale(0.5, 0.1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "Test for Censorship",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
		}
	))
end
