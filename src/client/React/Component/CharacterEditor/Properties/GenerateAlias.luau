--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
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
	if not fieldDefinition or fieldDefinition.Type ~= "GenerateAlias" then
		return
	end
	if not fieldCallback or not value or value.Type ~= "Text" then
		return
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.25),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Generate = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 170, 0),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 2,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.05, 0.2),
				Size = UDim2.fromScale(0.35, 0.1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "Generate Alias",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					fieldCallback(fieldDefinition, {
						Type = "Alias",
						Seed = RandomUtil.newSeed(Random.new()),
					})
				end,
			}),

			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0.45, 0.2),
				Size = UDim2.fromScale(0.5, 0.1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = value.Text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 10,
			}),
		}
	))
end
