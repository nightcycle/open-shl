--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
-- Components
-- Hooks
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/Types")
type Box = Types.Box
type EditorState = CharacterEditorType.EditorState
type FieldDefinition = CharacterEditorType.FieldDefinition
type Focus = Types.Focus
type PatternChoice = CharacterEditorType.PatternChoice
type TextureGroupKey = AppearanceType.TextureGroupKey
export type Properties = RobloxComponents.FrameProperties & {
	Focus: Focus,
	OnDone: () -> (),
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/CONSTANTS")
local PICKER = CONSTANTS.PICKER
-- the strip runs once around the colors from its top to its bottom, a straight ramp between each two of these
local HUE_STOPS: { number } = table.freeze({ 0, 0.165, 0.33, 0.5, 0.66, 0.825, 1 })
local HUE_COLORS: { Color3 } = table.freeze({
	Color3.new(1, 0, 0),
	Color3.new(1, 1, 0),
	Color3.new(0, 1, 0),
	Color3.new(0, 1, 1),
	Color3.new(0, 0, 1),
	Color3.new(1, 0, 1),
	Color3.new(1, 0, 0),
})
-- what the square is tinted with until the strip is pressed
local START_HUE = Color3.fromRGB(20, 166, 230)
-- the order the colors of an item are read in, so the row of what's on the mannequin doesn't shuffle
local GROUP_KEYS: { TextureGroupKey } =
	table.freeze({ "Primary" :: TextureGroupKey, "Secondary", "Tertiary", "Hair", "Skin" })
local NO_CHOICES: { PatternChoice } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function floorStep(value: number): number
	return math.floor(value * PICKER.STEPS) / PICKER.STEPS
end

local function getHue(alpha: number): Color3
	for index = 1, #HUE_STOPS - 1 do
		local from, to = HUE_STOPS[index], HUE_STOPS[index + 1]
		if alpha <= to then
			local color = HUE_COLORS[index]:Lerp(HUE_COLORS[index + 1], (alpha - from) / (to - from))
			return Color3.new(floorStep(color.R), floorStep(color.G), floorStep(color.B))
		end
	end
	return HUE_COLORS[#HUE_COLORS]
end

-- the square runs from white at its left to the hue at its right, and to black at its bottom
local function getShade(hue: Color3, paleness: number, brightness: number): Color3
	return Color3.new(
		(hue.R + paleness * (1 - hue.R)) * brightness,
		(hue.G + paleness * (1 - hue.G)) * brightness,
		(hue.B + paleness * (1 - hue.B)) * brightness
	)
end

-- where on a button a press landed, in hundredths of its size
local function getPressPosition(button: GuiObject, input: InputObject): Vector2?
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return nil
	end
	local size = button.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return nil
	end
	local offset = Vector2.new(input.Position.X, input.Position.Y) - button.AbsolutePosition
	return Vector2.new(floorStep(math.clamp(offset.X / size.X, 0, 1)), floorStep(math.clamp(offset.Y / size.Y, 0, 1)))
end

-- the colors the identity in front wears, each of them once
local function listWornColors(state: EditorState): { Color3 }
	local out: { Color3 } = {}
	local hexes: { [string]: true } = {}
	local function insert(color: Color3)
		local hex = color:ToHex()
		if not hexes[hex] and #out < PICKER.RECENT_COUNT then
			hexes[hex] = true
			table.insert(out, color)
		end
	end
	local identity = state.Character.Identities[state.IdentityKey] or state.Character.Identities.Main
	insert(identity.Appearance.SkinColor)
	for _, item in identity.Appearance.Items do
		for _, key: TextureGroupKey in GROUP_KEYS do
			local group = item.TextureGroups[key]
			if group then
				insert(group.Color)
			end
		end
	end
	return out
end

local function getIfBound(field: FieldDefinition, group: TextureGroupKey?): boolean
	if field.Type ~= "Color" and field.Type ~= "Pattern" then
		return false
	end
	local binding: CharacterEditorType.ColorBinding = field.Binding
	return binding.Type == "SkinColor" or group == nil or binding.Group == group
end

-- an opaque tag over a heading that's drawn into the art
local function tag(props: {
	Box: Box,
	Text: string,
	BackgroundColor3: Color3,
	TextColor3: Color3,
	ZIndex: number,
})
	local style = React.useContext(StyleContext)
	return e("TextLabel", {
		BackgroundColor3 = props.BackgroundColor3,
		BorderSizePixel = 0,
		FontFace = style.Fonts.Heading,
		Position = props.Box.Position,
		Size = props.Box.Size,
		Text = props.Text,
		TextColor3 = props.TextColor3,
		TextScaled = true,
		TextWrapped = true,
		ZIndex = props.ZIndex,
	})
end
-- Class
-- the one picker every color of the editor is picked in. it takes the place of the page it was opened from, and for
-- what can be patterned its square of colors swaps for the patterns
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local state = React.useContext(CharacterEditorStateContext)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local focus = props.Focus
	local hue, setHue = React.useState(START_HUE)
	-- a press on the strip keeps how pale + how bright the last pick was
	local shadeRef = React.useRef(Vector2.new(0, 1))
	local isPatternShown, setIsPatternShown = React.useState(false)

	local colorField: FieldDefinition?, patternField: FieldDefinition? = nil, nil
	if state and CharacterEditorDefinition.fixPath(state.Path) == CharacterEditorDefinition.fixPath(focus.Path) then
		for _, field in CharacterEditorUtil.listFields(state) do
			if not getIfBound(field, focus.Group) then
				continue
			end
			if field.Type == "Color" then
				colorField = colorField or field
			elseif field.Type == "Pattern" then
				patternField = patternField or field
			end
		end
	end
	local function pickColor(color: Color3)
		if fieldCallback and colorField then
			fieldCallback(colorField, {
				Type = "Color",
				Color = color,
			})
		end
	end

	local recents: { [string]: React.ReactNode } = {}
	local wornColors: { Color3 } = if state then listWornColors(state) else {}
	for index, color in wornColors do
		recents[`Recent-{index}`] = e("ImageButton", {
			BackgroundColor3 = color,
			BorderColor3 = PICKER.RECENT_BORDER_COLOR,
			BorderSizePixel = PICKER.RECENT_BORDER_SIZE,
			LayoutOrder = index,
			Size = UDim2.fromScale(PICKER.RECENT_SIZE, PICKER.RECENT_SIZE),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			[React.Event.Activated] = function()
				pickColor(color)
			end,
		})
	end

	local cells: { [string]: React.ReactNode } = {}
	local choices: { PatternChoice } = CharacterEditorDefinition.PATTERN_CHOICES or NO_CHOICES
	for index, choice in choices do
		local icon = choice.Icon
		cells[`Pattern-{index}`] = e("ImageButton", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Image = if not icon then "" elseif icon.Type == "Sprite" then icon.SheetUrl else icon.Url,
			ImageRectOffset = if icon and icon.Type == "Sprite" then icon.Position else nil,
			ImageRectSize = if icon and icon.Type == "Sprite" then icon.Size else nil,
			LayoutOrder = index,
			[React.Event.Activated] = function()
				if fieldCallback and patternField then
					fieldCallback(patternField, {
						Type = "Pattern",
						Material = choice.Material,
						Pattern = choice.Pattern,
					})
				end
			end,
		})
	end

	local isPatterns = isPatternShown and patternField ~= nil
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Art = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = PICKER.ART,
				Position = CONSTANTS.PAGE_ART_BOX.Position,
				Size = CONSTANTS.PAGE_ART_BOX.Size,
			}),
			Cover = e("Frame", {
				BackgroundColor3 = PICKER.COVER_COLOR,
				BorderSizePixel = 0,
				Position = PICKER.COVER_BOX.Position,
				Size = PICKER.COVER_BOX.Size,
				ZIndex = 2,
			}),
			Heading = e(tag, {
				Box = PICKER.HEADING.Box,
				Text = PICKER.HEADING.Text,
				BackgroundColor3 = style.Palette.Field,
				TextColor3 = style.Palette.Accent,
				ZIndex = 3,
			}),

			-- there's nothing to switch to for a color that takes no pattern
			SwitchArt = patternField and e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = if isPatterns then PICKER.COLORS_ART else PICKER.PATTERNS_ART,
				Position = PICKER.SWITCH_ART_BOX.Position,
				Size = PICKER.SWITCH_ART_BOX.Size,
				ZIndex = 2,
			}),
			SwitchTag = patternField and e(tag, {
				Box = PICKER.SWITCH_TAG_BOX,
				Text = if isPatterns then PICKER.COLORS_TEXT else PICKER.PATTERNS_TEXT,
				BackgroundColor3 = PICKER.SWITCH_TAG_COLOR,
				TextColor3 = PICKER.TAG_TEXT_COLOR,
				ZIndex = 3,
			}),
			Switch = patternField and e("ImageButton", {
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				Position = PICKER.SWITCH_BOX.Position,
				Size = PICKER.SWITCH_BOX.Size,
				ZIndex = 4,
				[React.Event.Activated] = function()
					setIsPatternShown(not isPatterns)
				end,
			}),

			Hue = not isPatterns and e("ImageButton", {
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Image = PICKER.HUE_IMAGE,
				Position = PICKER.HUE_BOX.Position,
				Size = PICKER.HUE_BOX.Size,
				ZIndex = 4,
				[React.Event.InputBegan] = function(button: ImageButton, input: InputObject)
					local position = getPressPosition(button, input)
					if position then
						local pickedHue = getHue(position.Y)
						setHue(pickedHue)
						pickColor(getShade(pickedHue, shadeRef.current.X, shadeRef.current.Y))
					end
				end,
			}),
			Shade = not isPatterns and e("ImageButton", {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Image = PICKER.SHADE_IMAGE,
				ImageColor3 = hue,
				Position = PICKER.SHADE_BOX.Position,
				Size = PICKER.SHADE_BOX.Size,
				ZIndex = 4,
				[React.Event.InputBegan] = function(button: ImageButton, input: InputObject)
					local position = getPressPosition(button, input)
					if position then
						shadeRef.current = Vector2.new(1 - position.X, 1 - position.Y)
						pickColor(getShade(hue, shadeRef.current.X, shadeRef.current.Y))
					end
				end,
			}),
			Patterns = isPatterns and e("Frame", {
				BackgroundTransparency = 1,
				Position = PICKER.GRID_BOX.Position,
				Size = PICKER.GRID_BOX.Size,
				ZIndex = 4,
			}, {
				UIGridLayout = e("UIGridLayout", {
					CellPadding = PICKER.GRID_CELL_PADDING,
					CellSize = PICKER.GRID_CELL_SIZE,
					FillDirection = Enum.FillDirection.Horizontal,
					FillDirectionMaxCells = PICKER.GRID_COLUMNS,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				Cells = e(React.Fragment, {}, cells),
			}),

			Recents = e("Frame", {
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = PICKER.RECENT_BOX.Position,
				Size = PICKER.RECENT_BOX.Size,
				ZIndex = 4,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(PICKER.RECENT_PADDING, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				Swatches = e(React.Fragment, {}, recents),
			}),

			DoneArt = e("ImageLabel", {
				BackgroundTransparency = 1,
				Image = PICKER.DONE_ART,
				Position = PICKER.DONE_ART_BOX.Position,
				Size = PICKER.DONE_ART_BOX.Size,
				ZIndex = 2,
			}),
			DoneTag = e(tag, {
				Box = PICKER.DONE_TAG_BOX,
				Text = PICKER.DONE_TEXT,
				BackgroundColor3 = style.Palette.Accent,
				TextColor3 = PICKER.TAG_TEXT_COLOR,
				ZIndex = 3,
			}),
			Done = e("ImageButton", {
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				Position = PICKER.DONE_BOX.Position,
				Size = PICKER.DONE_BOX.Size,
				ZIndex = 4,
				[React.Event.Activated] = props.OnDone,
			}),
		}
	))
end
