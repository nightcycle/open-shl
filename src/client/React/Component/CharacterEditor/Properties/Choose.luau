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
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			TextLabel = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Size = UDim2.fromScale(1, 0.15),
				Text = "Choose One:",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			Buttons = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.1525),
				Size = UDim2.fromScale(1, 0.35),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				Evil = e("TextButton", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0.02, 0),
					Size = UDim2.fromScale(0.3, 0.3),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = "Evil",
					TextSize = 14,
				}),

				Neutral = e("TextButton", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0.345, 0),
					Size = UDim2.fromScale(0.3, 0.3),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = "Neutral",
					TextSize = 14,
				}),

				Good = e("TextButton", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0.67, 0),
					Size = UDim2.fromScale(0.3, 0.3),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = "Good",
					TextSize = 14,
				}),
			}),
		}
	))
end
