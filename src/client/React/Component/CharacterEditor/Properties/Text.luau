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
local CharacterEditorTextFilterCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/TextFilterCallback")
-- Types
local FieldTypes = require("./Types")
export type Properties = FieldTypes.FieldProperties
type LayoutInfo = {
	HEIGHT: number,
	BOX_POSITION: number,
	BOX_SIZE: number,
	TEST_POSITION: number,
}
-- Constants
-- where an entry keeps its box + the button under it, in widths of the field
local SINGLE_LINE: LayoutInfo = table.freeze({
	HEIGHT = 0.35,
	BOX_POSITION = 0.0625,
	BOX_SIZE = 0.125,
	TEST_POSITION = 0.25,
})
local MULTI_LINE: LayoutInfo = table.freeze({
	HEIGHT = 1,
	BOX_POSITION = 0.0625,
	BOX_SIZE = 0.75,
	TEST_POSITION = 0.875,
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local filterText = React.useContext(CharacterEditorTextFilterCallback)
	local value = useFieldValue()
	if not fieldDefinition or fieldDefinition.Type ~= "Text" then
		return
	end
	if not fieldCallback or not value or value.Type ~= "Text" then
		return
	end
	local LAYOUT = if fieldDefinition.IsMultiLine then MULTI_LINE else SINGLE_LINE
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, LAYOUT.HEIGHT),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			TextBox = e(
				"TextBox",
				{
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.3,
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					MultiLine = fieldDefinition.IsMultiLine == true,
					ClearTextOnFocus = false,
					PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
					Position = UDim2.fromScale(0.062, LAYOUT.BOX_POSITION / LAYOUT.HEIGHT),
					Size = UDim2.fromScale(0.875, LAYOUT.BOX_SIZE / LAYOUT.HEIGHT),
					Text = value.Text,
					PlaceholderText = fieldDefinition.Description,
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					[React.Change.Text] = function(textBox: TextBox)
						local text = textBox.Text
						local length = utf8.len(text)
						if not length then
							return
						end
						-- a draft that already holds the cut text has nothing to change, so the box is cut here too
						local maxLength = fieldDefinition.MaxLength
						if maxLength and length > maxLength then
							local endIndex = utf8.offset(text, math.max(0, math.floor(maxLength)) + 1)
							text = string.sub(text, 1, (endIndex or (#text + 1)) - 1)
							textBox.Text = text
						end
						fieldCallback(fieldDefinition, {
							Type = "Text",
							Text = text,
						})
					end,
				} :: RobloxComponents.TextBoxProperties
			),

			Test = filterText and e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 170, 255),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 2,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.25, LAYOUT.TEST_POSITION / LAYOUT.HEIGHT),
				Size = UDim2.fromScale(0.5, 0.1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "Test for Censorship",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					filterText(fieldDefinition)
				end,
			}),
		}
	))
end
