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
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/CONSTANTS")
-- a stack of choices in widths of the field: the header, then a row every tenth of a width
local HEADER_POSITION = 0.05
local HEADER_HEIGHT = 0.1
local ROW_POSITION = 0.2
local ROW_STEP = 0.1
local ROW_HEIGHT = 0.08
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local value = useFieldValue()
	if not fieldDefinition or fieldDefinition.Type ~= "Choose" then
		return
	end
	if not fieldCallback or not value or value.Type ~= "Choice" then
		return
	end
	local binding = fieldDefinition.Binding
	local choiceCount = #fieldDefinition.Choices
	if fieldDefinition.IsVertical then
		local height = ROW_POSITION + ROW_STEP * choiceCount
		local rows: { [string]: React.ReactNode } = {}
		for i, choice in fieldDefinition.Choices do
			if choice.Type ~= "Text" then
				warn(`expected text for choice {choice.Value}`)
				continue
			end
			local isSelected = choice.Value == value.Value
			rows[`Button{i}`] = e("TextButton", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = isSelected and 5 or 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.025, (ROW_POSITION + ROW_STEP * (i - 1)) / height),
				Size = UDim2.fromScale(0.95, ROW_HEIGHT),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = choice.Text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					fieldCallback(fieldDefinition, {
						Type = "Choice",
						Value = choice.Value,
					})
				end,
			})
		end
		return e(RobloxComponents.Frame(
			{
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, height),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			} :: RobloxComponents.FrameProperties,
			props,
			{
				TextLabel = fieldDefinition.Description and e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/SourceSansPro.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromScale(0, HEADER_POSITION / height),
					Size = UDim2.fromScale(1, HEADER_HEIGHT),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = fieldDefinition.Description,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),

				Buttons = e(React.Fragment, {}, rows),
			}
		))
	end

	-- the two rows of the alignment are told apart by their shade
	local isShaded = binding.Type == "Alignment" and binding.Axis == "Order"
	local buttons: { [string]: React.ReactNode } = {}
	for i, choice in fieldDefinition.Choices do
		if choice.Type ~= "Text" then
			warn(`expected text for choice {choice.Value}`)
			continue
		end
		local width = 1 / choiceCount
		local padPx = 7
		local isSelected = choice.Value == value.Value
		buttons[`Button{i}`] = e("TextButton", {
			BackgroundColor3 = isShaded and Color3.fromRGB(171, 171, 171) or Color3.new(1, 1, 1),
			BorderColor3 = isSelected and CONSTANTS.SELECTION_COLOR or Color3.new(1, 1, 1),
			BorderSizePixel = isSelected and 3 or 1,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Position = UDim2.new((i - 1) * width, padPx * (i - 0.5) / choiceCount, 0, 0),
			Size = UDim2.new(width, -padPx, 1, 0),
			Text = choice.Text,
			TextSize = 14,
			ZIndex = isSelected and 2 or 1,
			[React.Event.Activated] = function()
				fieldCallback(fieldDefinition, {
					Type = "Choice",
					Value = choice.Value,
				})
			end,
		})
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
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
