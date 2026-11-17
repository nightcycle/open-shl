--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Components
-- Hooks
local useFieldValue =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFieldValue")
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
local PickerPowerIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/PickerPowerId")
local SetPickerPowerIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPickerPowerId")
-- Types
local FieldTypes = require("./Types")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
export type Properties = FieldTypes.FieldProperties
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/CONSTANTS")
-- the list in widths of the field: the header of a group, then a row per power
local HEADER_STEP = 0.14
local HEADER_HEIGHT = 0.1
local ROW_STEP = 0.18
local ROW_HEIGHT = 0.15
local REGULAR_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local BOLD_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getNextColor(colors: { Color3 }, color: Color3, direction: number): Color3
	-- compared as hex, a color that went through a save may not be bit equal to its choice
	local hex = color:ToHex()
	for i, colorChoice in colors do
		if colorChoice:ToHex() == hex then
			return colors[(i - 1 + direction) % #colors + 1]
		end
	end
	return if direction > 0 then colors[1] else colors[#colors]
end

local function pickerButton(props: RobloxComponents.TextButtonProperties)
	return e(RobloxComponents.TextButton({
		BackgroundTransparency = 0.1,
		BorderColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 3,
		FontFace = BOLD_FONT,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		ZIndex = 4,
	}, props))
end

local function colorPicker(props: {
	Color: Color3,
	OnStep: (direction: number) -> (),
	OnDone: () -> (),
})
	return e("Frame", {
		-- a press that misses the buttons doesn't reach the row under it
		Active = true,
		BackgroundColor3 = Color3.new(),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	}, {
		Left = e(
			pickerButton,
			{
				BackgroundColor3 = Color3.new(),
				Position = UDim2.fromScale(0.025, 0.1),
				Size = UDim2.fromScale(0.15, 0.8),
				Text = "<",
				[React.Event.Activated] = function()
					props.OnStep(-1)
				end,
			} :: RobloxComponents.TextButtonProperties
		),
		Swatch = e("Frame", {
			BackgroundColor3 = props.Color,
			BorderColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.225, 0.2),
			Size = UDim2.fromScale(0.175, 0.6),
			ZIndex = 4,
		}),
		Right = e(
			pickerButton,
			{
				BackgroundColor3 = Color3.new(),
				Position = UDim2.fromScale(0.45, 0.1),
				Size = UDim2.fromScale(0.15, 0.8),
				Text = ">",
				[React.Event.Activated] = function()
					props.OnStep(1)
				end,
			} :: RobloxComponents.TextButtonProperties
		),
		Done = e(
			pickerButton,
			{
				BackgroundColor3 = Color3.fromRGB(0, 170, 0),
				Position = UDim2.fromScale(0.65, 0.15),
				Size = UDim2.fromScale(0.3, 0.7),
				Text = "Done",
				[React.Event.Activated] = props.OnDone,
			} :: RobloxComponents.TextButtonProperties
		),
	})
end

local function choiceRow(
	props: {
		LayoutOrder: number,
		Choice: ChoiceDefinition,
		IsSelected: boolean,
		PickerColor: Color3?, -- the color it's tinted with while its picker is open
		OnClick: () -> (),
		OnStep: (direction: number) -> (),
		OnDone: () -> (),
	}
)
	local choice = props.Choice
	local icon = if choice.Type == "Text" then nil else choice.Icon
	return e("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, ROW_STEP),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
	}, {
		ImageLabel = icon and e("ImageLabel", {
			BackgroundTransparency = 1,
			Image = if icon.Type == "Sprite" then icon.SheetUrl else icon.Url,
			ImageRectOffset = if icon.Type == "Sprite" then icon.Position else nil,
			ImageRectSize = if icon.Type == "Sprite" then icon.Size else nil,
			Position = UDim2.fromScale(0.02, 0),
			Size = UDim2.fromScale(ROW_HEIGHT, ROW_HEIGHT),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}),

		TextButton = e(
			"TextButton",
			{
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = props.IsSelected and CONSTANTS.SELECTION_COLOR or Color3.new(1, 1, 1),
				BorderSizePixel = props.IsSelected and 3 or 1,
				FontFace = REGULAR_FONT,
				Position = UDim2.fromScale(0.19, 0),
				Size = UDim2.fromScale(0.8, ROW_HEIGHT),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = if choice.Type == "Icon" then "" else choice.Text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = props.IsSelected and 2 or 1,
				[React.Event.Activated] = props.OnClick,
			} :: RobloxComponents.TextButtonProperties,
			{
				ColorPicker = props.PickerColor and e(colorPicker, {
					Color = props.PickerColor,
					OnStep = props.OnStep,
					OnDone = props.OnDone,
				}),
			}
		),
	})
end
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local pickerPowerId = React.useContext(PickerPowerIdContext)
	local setPickerPowerId = React.useContext(SetPickerPowerIdContext)
	local value = useFieldValue()
	local colors = React.useMemo(function(): { [string]: { Color3 } }
		local out: { [string]: { Color3 } } = {}
		if fieldDefinition and fieldDefinition.Type == "ChoiceList" then
			for _, choice in fieldDefinition.Choices do
				local powerDefRes = PowerDefinition.get(choice.Value)
				local colorGroup = if powerDefRes.IsOk then powerDefRes.Value.ColorGroups.Primary else nil
				if colorGroup and #colorGroup.Choices > 0 then
					out[choice.Value] = colorGroup.Choices
				end
			end
		end
		return out
	end, { fieldDefinition })
	if not fieldDefinition or fieldDefinition.Type ~= "ChoiceList" then
		return
	end
	if not fieldCallback or not value or value.Type ~= "Powers" then
		return
	end

	local rows: { [string]: React.ReactNode } = {}
	for i, choice in fieldDefinition.Choices do
		local powerId: string = choice.Value
		local powerValue = value.Powers[powerId]
		local isSelected = powerValue ~= nil
		local powerColors: { Color3 }? = colors[powerId]
		local pickerColor: Color3? = if powerColors
				and powerValue
				and pickerPowerId == powerId
			then powerValue.Color
			else nil
		rows[`Choice-{i}`] = e(choiceRow, {
			LayoutOrder = i,
			Choice = choice,
			IsSelected = isSelected,
			PickerColor = pickerColor,
			OnClick = function()
				fieldCallback(fieldDefinition, {
					Type = "Power",
					Id = powerId,
					IsSelected = not isSelected,
				})
				-- any press closes the picker that's open, a power that comes in colors opens its own as it's picked
				if setPickerPowerId then
					setPickerPowerId(if not isSelected and powerColors then powerId else nil)
				end
			end,
			OnStep = function(direction: number)
				if powerColors and pickerColor then
					fieldCallback(fieldDefinition, {
						Type = "PowerColor",
						Id = powerId,
						Color = getNextColor(powerColors, pickerColor, direction),
					})
				end
			end,
			OnDone = function()
				if setPickerPowerId then
					setPickerPowerId(nil)
				end
			end,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, HEADER_STEP + ROW_STEP * #fieldDefinition.Choices),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Header = e("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				Size = UDim2.fromScale(1, HEADER_STEP),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				TextLabel = fieldDefinition.Description and e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = BOLD_FONT,
					Size = UDim2.fromScale(1, HEADER_HEIGHT),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = fieldDefinition.Description,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
			}),

			Rows = e(React.Fragment, {}, rows),
		}
	))
end
