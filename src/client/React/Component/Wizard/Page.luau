--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
-- Components
local Row = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Row")
local Swatches = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Swatches")
-- Hooks
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Types")
type Character = CharacterType.Character
type EditorState = CharacterEditorType.EditorState
type FieldDefinition = CharacterEditorType.FieldDefinition
type PageInfo = Types.PageInfo
type PageRequirement = CharacterEditorType.PageRequirement
type RowInfo = Types.RowInfo
type Step = Types.Step
-- an item a row steps to: where its page is + the field that puts it on
type ItemEntry = {
	Path: string,
	IsWorn: boolean,
	Toggle: FieldDefinition,
}
export type Properties = RobloxComponents.FrameProperties & {
	Step: Step,
	-- what the button the page is left by says in place of what it's for: why the walk couldn't end
	Notice: string?,
	-- the way on, with the draft as it's left. left out, the page is only looked at: one that's sliding off
	OnForward: ((draft: Character) -> ())?,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/CONSTANTS")
local ITEM_TAG: CharacterEditorType.Tag = "IsItemAdded"
local NO_FIELDS: { FieldDefinition } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the items of a list of the game's editor in its order. a place built for another game has no such list
local function listItems(state: EditorState, folderPath: string): { ItemEntry }
	local out: { ItemEntry } = {}
	local folderOpt = CharacterEditorDefinition.getPage(folderPath)
	if folderOpt.IsNone then
		return out
	end
	local folder = folderOpt.Value
	if folder.Type ~= "Default" or not folder.Children then
		return out
	end
	for _, child in folder.Children do
		if child.Type ~= "Item" then
			continue
		end
		local fields: { FieldDefinition } = child.Fields or NO_FIELDS
		for _, field in fields do
			if field.Type == "Toggle" and field.Focus == ITEM_TAG then
				table.insert(out, {
					Path = CharacterEditorDefinition.getChildPath(folderPath, child),
					IsWorn = CharacterEditorUtil.getIfItemWorn(state, child.DefinitionId),
					Toggle = field,
				})
				break
			end
		end
	end
	return out
end

-- the fields of a page that pick a color, in the order the page is stopped on for them
local function listColorFields(path: string): { FieldDefinition }
	local out: { FieldDefinition } = {}
	local pageOpt = CharacterEditorDefinition.getPage(path)
	if pageOpt.IsNone or pageOpt.Value.Type ~= "Default" then
		return out
	end
	local fields: { FieldDefinition } = pageOpt.Value.Fields or NO_FIELDS
	for _, field in fields do
		if field.Type == "Color" then
			table.insert(out, field)
		end
	end
	return out
end

-- what the identity in focus has to wear before the page is left
local function getRequirement(state: EditorState, path: string): PageRequirement?
	local pageOpt = CharacterEditorDefinition.getPage(path)
	if pageOpt.IsNone or pageOpt.Value.Type ~= "Default" then
		return nil
	end
	local requirement = pageOpt.Value.Requirement
	if not requirement then
		return nil
	end
	local identity = state.Character.Identities[state.IdentityKey] or state.Character.Identities.Main
	for _, item in identity.Appearance.Items do
		local indexRes = AppearanceItemDefinition.getIndex(item.DefinitionId)
		if
			indexRes.IsOk
			and indexRes.Value.Group == requirement.Group
			and indexRes.Value.Category == requirement.Category
		then
			return nil
		end
	end
	return requirement
end

local function panelTitle(props: {
	Page: PageInfo,
	Text: string,
	TextColor3: Color3,
})
	local style = React.useContext(StyleContext)
	return e("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = style.Fonts.Heading,
		Position = props.Page.TitleBox.Position,
		Size = props.Page.TitleBox.Size,
		Text = props.Text,
		TextColor3 = props.TextColor3,
		TextScaled = true,
		TextWrapped = true,
	})
end
-- Class
-- one stop of the walk: a page that hides the booth, or the two see-through panels at the sides of it with the
-- controls of the page in the left one + a word about them in the right one. it's drawn over the editor of the game
-- the place is built for: in a place of another game the rows have nothing to step through + a color paints nothing
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local state = React.useContext(CharacterEditorStateContext)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local setPath = React.useContext(SetPathContext)
	-- why the page wasn't left, for as long as the button says it
	local refusal: string?, setRefusal: (string?) -> () = useTimedState(CONSTANTS.NOTICE_DURATION)
	local step = props.Step
	local page = step.Page
	local onForward = props.OnForward
	if not state or not fieldCallback or not setPath then
		return nil
	end
	local palette = style.Palette
	local border = style.Border
	local isCover = page.Kind == "Cover"

	local function goOn()
		if not onForward then
			return
		end
		local requirement = getRequirement(state, page.Key)
		if requirement then
			setRefusal(requirement.Text)
			return
		end
		onForward(state.Character)
	end

	-- an arrow puts the next one of the list on, the one after the last is the first again. with nothing of the list
	-- worn yet either arrow starts at its own end
	local function stepRow(row: RowInfo, direction: number)
		local items = listItems(state, row.Folder)
		if #items == 0 then
			return
		end
		local wornIndex: number? = nil
		for index, item in items do
			if item.IsWorn then
				wornIndex = index
				break
			end
		end
		local index = if wornIndex then (wornIndex - 1 + direction) % #items + 1 elseif direction > 0 then 1 else #items
		local item = items[index]
		setPath(item.Path)
		fieldCallback(item.Toggle, {
			Type = "Toggle",
			IsSelected = true,
		})
	end

	-- a press on a swatch is the pick + the way on at once, whether or not there's anything to paint
	local function pickColor(index: number)
		if not onForward then
			return
		end
		local field = listColorFields(page.Key)[step.Index]
		local colors: { Color3 } = CharacterEditorDefinition.PALETTE or {}
		local color = colors[index]
		local draft = state.Character
		if field and color then
			local edit: CharacterEditorType.FieldEdit = {
				Type = "Color",
				Color = color,
			}
			-- the walk moves on in the same press, so what the pick makes of the draft is worked out here as well
			local stateRes = CharacterEditorUtil.write(state, field, edit)
			if stateRes.IsOk then
				draft = stateRes.Value.Character
			end
			fieldCallback(field, edit)
		end
		onForward(draft)
	end

	local forward = page.Forward
	local notice = refusal or props.Notice
	local forwardButton: React.ReactNode = nil
	if forward then
		forwardButton = e("TextButton", {
			Active = onForward ~= nil,
			-- a button that didn't do what it's for is red for as long as it says why
			BackgroundColor3 = if notice
				then palette.Negative
				elseif forward.IsCard then CONSTANTS.CARD_COLOR
				else palette.Field,
			BorderColor3 = border.Color3,
			BorderSizePixel = if forward.IsCard then border.SizePixel else 0,
			FontFace = if forward.IsCard then style.Fonts.Body else style.Fonts.Heading,
			Position = forward.Box.Position,
			Size = forward.Box.Size,
			Text = notice or forward.Text,
			-- a card is written on in the dark of its edge
			TextColor3 = if forward.IsCard and not notice then border.Color3 else palette.Text,
			TextScaled = true,
			TextWrapped = true,
			[React.Event.Activated] = goOn,
		})
	end

	local children: { [string]: React.ReactNode } = {}
	if isCover then
		children.Title = e(panelTitle, {
			Page = page,
			Text = step.Title,
			TextColor3 = palette.Warning,
		})
		local lines: { Types.LineInfo } = page.Lines or {}
		for index, line in lines do
			children[`Line-{index}`] = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = if line.IsBold then style.Fonts.Heading else CONSTANTS.COVER_FONT,
				Position = line.Box.Position,
				Size = line.Box.Size,
				Text = line.Text,
				TextColor3 = if line.IsWarning then palette.Warning else palette.Text,
				TextScaled = true,
				TextWrapped = true,
			})
		end
		children.Forward = forwardButton
	else
		local controls: { [string]: React.ReactNode } = {}
		controls.Title = e(panelTitle, {
			Page = page,
			Text = step.Title,
			TextColor3 = palette.Text,
		})
		local rows: { RowInfo } = page.Rows or {}
		for _, row in rows do
			controls[`Row-{row.Text}`] = e(
				Row,
				{
					Position = row.Position,
					Size = CONSTANTS.ROW_SIZE,
					Text = row.Text,
					LeftPosition = CONSTANTS.ROW_LEFT_POSITION,
					RightPosition = CONSTANTS.ROW_RIGHT_POSITION,
					ArrowSize = CONSTANTS.ROW_ARROW_SIZE,
					NamePosition = CONSTANTS.ROW_NAME_POSITION,
					NameSize = CONSTANTS.ROW_NAME_SIZE,
					OnStep = if onForward
						then function(direction: number)
							stepRow(row, direction)
						end
						else nil,
				} :: Row.Properties
			)
		end
		if page.Kind == "Palette" then
			controls.Swatches = e(
				Swatches,
				{
					Position = CONSTANTS.GRID_POSITION,
					Size = CONSTANTS.GRID_SIZE,
					Colors = CONSTANTS.SWATCH_COLORS,
					ColumnCount = CONSTANTS.GRID_COLUMN_COUNT,
					OnPick = if onForward then pickColor else nil,
				} :: Swatches.Properties
			)
		end
		controls.Forward = forwardButton
		-- nothing is rented yet: the button is there the way it was whenever it couldn't be used
		if page.Rent then
			controls.Rent = e("TextLabel", {
				BackgroundColor3 = palette.Positive,
				BackgroundTransparency = CONSTANTS.RENT_TRANSPARENCY,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Heading,
				Position = page.Rent.Position,
				Size = page.Rent.Size,
				Text = CONSTANTS.RENT_TEXT,
				TextColor3 = palette.Text,
				TextScaled = true,
				TextTransparency = CONSTANTS.RENT_TRANSPARENCY,
				TextWrapped = true,
			})
		end
		children.Panel = e("Frame", {
			BackgroundColor3 = palette.Field,
			BackgroundTransparency = CONSTANTS.PANEL_TRANSPARENCY,
			BorderSizePixel = 0,
			Position = CONSTANTS.PANEL_POSITION,
			Size = page.PanelSize,
		}, controls)
		children.Help = e("Frame", {
			BackgroundColor3 = palette.Field,
			BackgroundTransparency = CONSTANTS.PANEL_TRANSPARENCY,
			BorderSizePixel = 0,
			Position = CONSTANTS.HELP_PANEL_POSITION,
			Size = CONSTANTS.HELP_PANEL_SIZE,
		}, {
			Description = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Heading,
				Position = CONSTANTS.HELP_POSITION,
				Size = CONSTANTS.HELP_SIZE,
				Text = page.Help or "",
				TextColor3 = palette.Text,
				TextScaled = true,
				TextWrapped = true,
			}),
		})
	end

	return e(RobloxComponents.Frame({
		-- a cover takes the presses that would land on what it hides
		Active = isCover,
		BackgroundColor3 = CONSTANTS.COVER_COLOR,
		BackgroundTransparency = if isCover then 0 else 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, props, children))
end
