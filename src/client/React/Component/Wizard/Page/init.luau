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
local Gate = require("@self/Gate")
-- Components
local Names = require("@self/Names")
local Stepper = require("@self/Stepper")
local Swatches = require("@self/Swatches")
-- Hooks
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorRefusalContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Refusal")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local SessionOwnedContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Owned")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EditorTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/Types")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Types")
type Character = CharacterType.Character
type EditorState = CharacterEditorType.EditorState
type FieldDefinition = CharacterEditorType.FieldDefinition
type FilteredText = EditorTypes.FilteredText
type PageInfo = Types.PageInfo
type PageRequirement = CharacterEditorType.PageRequirement
type RowInfo = Types.RowInfo
type Step = Types.Step
export type Properties = RobloxComponents.FrameProperties & {
	Step: Step,
	-- what the button the page is left by says in place of what it's for: why the walk couldn't end
	Notice: string?,
	FilteredText: FilteredText?, -- the last answer of the text filter, for a page names are typed on
	IsPeaceful: boolean?, -- whether the player sat fights out, for the page that asks
	OnPeaceful: ((isPeaceful: boolean) -> ())?,
	-- the way on, with the draft as it's left. left out, the page is only looked at: one that's sliding off
	OnForward: ((draft: Character) -> ())?,
	OnPurchase: ((id: string) -> ())?, -- asks for what opens an item or a power the game holds back, by its id
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/CONSTANTS")
local NO_FIELDS: { FieldDefinition } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

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

-- whether a field is one of a page's own: what a field of another page was turned down for isn't this page's to say
local function getIfPageField(path: string, field: FieldDefinition): boolean
	local pageOpt = CharacterEditorDefinition.getPage(path)
	if pageOpt.IsNone or pageOpt.Value.Type ~= "Default" then
		return false
	end
	local fields: { FieldDefinition } = pageOpt.Value.Fields or NO_FIELDS
	return table.find(fields, field) ~= nil
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
-- the place is built for: in a place of another game the rows have nothing to step through, a color paints nothing
-- + a name has no box that takes it
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local state = React.useContext(CharacterEditorStateContext)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local editRefusal = React.useContext(CharacterEditorRefusalContext)
	local owned = React.useContext(SessionOwnedContext)
	local edited: Character? = if state then state.Character else nil
	-- the slot as it's stored: in here the character of the context is the draft
	local stored: Character? = if state then state.SavedCharacter else nil
	-- what the draft is short of, as the server is going to ask it once the walk hands the draft in
	local hold: Gate.Hold? = React.useMemo(function(): Gate.Hold?
		return if edited and stored then Gate.new(edited, stored, owned) else nil
	end, { edited :: any, stored :: any, owned :: any })
	-- why the page wasn't left, for as long as the button says it
	local refusal: string?, setRefusal: (string?) -> () = useTimedState(CONSTANTS.NOTICE_DURATION)
	local step = props.Step
	local page = step.Page
	local onForward = props.OnForward
	if not state or not fieldCallback then
		return nil
	end
	local palette = style.Palette
	local border = style.Border
	local isCover = page.Kind == "Cover"
	-- a page with a row that has something on its player is short of isn't left ahead: the way back stays
	local isHeld = hold ~= nil and Gate.getIfPageHeld(hold, state, page)

	local function goOn()
		if not onForward or isHeld then
			return
		end
		local requirement = getRequirement(state, page.Key)
		if requirement then
			setRefusal(requirement.Text)
			return
		end
		onForward(state.Character)
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
	-- a list that turned a pick down has nowhere of its own to say so, every other field that does is heard of in the
	-- output
	local listRefusal: string? = if onForward
			and editRefusal
			and editRefusal.Field.Type == "ChoiceList"
			and getIfPageField(page.Key, editRefusal.Field)
		then editRefusal.Message
		else nil
	local notice = refusal or listRefusal or props.Notice
	local forwardButton: React.ReactNode = nil
	if forward then
		forwardButton = e("TextButton", {
			Active = onForward ~= nil and not isHeld,
			-- a button that didn't do what it's for is red for as long as it says why, one that takes no press for
			-- as long as it doesn't
			BackgroundColor3 = if notice or isHeld
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
				Stepper,
				{
					Row = row,
					PageKey = page.Key,
					IsLive = onForward ~= nil,
					IsPeaceful = props.IsPeaceful,
					OnPeaceful = props.OnPeaceful,
					Hold = hold,
					OnPurchase = props.OnPurchase,
				} :: Stepper.Properties
			)
		end
		if page.Kind == "Names" then
			controls.Names = e(
				Names,
				{
					Page = page,
					IsLive = onForward ~= nil,
					FilteredText = props.FilteredText,
				} :: Names.Properties
			)
		elseif page.Kind == "Palette" then
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
