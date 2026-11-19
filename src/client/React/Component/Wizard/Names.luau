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
local CharacterEditorTextFilterCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/TextFilterCallback")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local EditorTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/Types")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Types")
type EditorState = CharacterEditorType.EditorState
type FieldDefinition = CharacterEditorType.FieldDefinition
type FilteredText = EditorTypes.FilteredText
type NameInfo = Types.NameInfo
type PageInfo = Types.PageInfo
export type Properties = {
	Page: PageInfo,
	IsLive: boolean?, -- left out, the boxes are only looked at
	FilteredText: FilteredText?, -- the last answer of the filter, whichever box it was for
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/CONSTANTS")
local NO_FIELDS: { FieldDefinition } = table.freeze({})
local NO_NAMES: { NameInfo } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the text fields of the page in their order, a place built for another game may have none
local function listTextFields(pageKey: string): { FieldDefinition }
	local out: { FieldDefinition } = {}
	local pageOpt = CharacterEditorDefinition.getPage(pageKey)
	if pageOpt.IsNone or pageOpt.Value.Type ~= "Default" then
		return out
	end
	local fields: { FieldDefinition } = pageOpt.Value.Fields or NO_FIELDS
	for _, field in fields do
		if field.Type == "Text" then
			table.insert(out, field)
		end
	end
	return out
end

local function getText(state: EditorState, field: FieldDefinition): string
	local value = CharacterEditorUtil.read(state, field)
	return if value.Type == "Text" then value.Text else ""
end
-- Class
-- a bar for each name of the page with a white box in it to type the name in, + the button that shows what the
-- names read like to everybody else. a box says what it's for until something is typed
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local state = React.useContext(CharacterEditorStateContext)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local filterText = React.useContext(CharacterEditorTextFilterCallback)
	-- the names that are still to go through the filter: it's asked about one at a time, an answer tells for which
	-- text it is + not which box held it
	local queueRef = React.useRef({} :: { FieldDefinition })
	local page = props.Page
	local isLive = props.IsLive == true
	local filteredText = props.FilteredText

	local function filterNext()
		local field = table.remove(queueRef.current, 1)
		if field and filterText then
			filterText(field)
		end
	end
	-- the answer for one name is the turn of the next
	React.useEffect(function()
		if filteredText then
			filterNext()
		end
		return function() end
	end, { filteredText })

	if not state or not fieldCallback then
		return nil
	end
	local palette = style.Palette
	local border = style.Border
	local fields = listTextFields(page.Key)

	local children: { [string]: React.ReactNode } = {}
	for index, name in page.Names or NO_NAMES do
		local field = fields[name.Field]
		local maxLength: number? = if field and field.Type == "Text" then field.MaxLength else nil
		children[`Name-{index}`] = e("Frame", {
			BackgroundColor3 = palette.Field,
			BorderSizePixel = 0,
			Position = name.Position,
			Size = CONSTANTS.ROW_SIZE,
		}, {
			TextBox = e(
				"TextBox",
				{
					BackgroundColor3 = CONSTANTS.CARD_COLOR,
					BorderColor3 = border.Color3,
					BorderSizePixel = border.SizePixel,
					FontFace = style.Fonts.Body,
					-- what the box is for was its text, written like any other until the box was typed in
					PlaceholderColor3 = border.Color3,
					PlaceholderText = if field and field.Type == "Text" then field.Description else nil,
					Position = CONSTANTS.NAME_BOX_POSITION,
					Size = CONSTANTS.NAME_BOX_SIZE,
					Text = if field then getText(state, field) else "",
					TextColor3 = border.Color3,
					TextEditable = isLive and field ~= nil,
					TextSize = style.TextSizes.Body,
					[React.Change.Text] = if isLive and field
						then function(textBox: TextBox)
							local text = textBox.Text
							local length = utf8.len(text)
							if not length then
								return
							end
							-- a draft that already holds the cut text has nothing to change, so the box is cut here too
							if maxLength and length > maxLength then
								local endIndex = utf8.offset(text, math.max(0, math.floor(maxLength)) + 1)
								text = string.sub(text, 1, (endIndex or (#text + 1)) - 1)
								textBox.Text = text
							end
							fieldCallback(field, {
								Type = "Text",
								Text = text,
							})
						end
						else nil,
				} :: RobloxComponents.TextBoxProperties
			),
		})
	end

	local test = page.Test
	if test then
		children.Test = e("TextButton", {
			Active = isLive,
			BackgroundColor3 = palette.Accent,
			BorderSizePixel = 0,
			FontFace = style.Fonts.Heading,
			Position = test.Box.Position,
			Size = test.Box.Size,
			Text = test.Text,
			TextColor3 = palette.TextOnAccent,
			TextScaled = true,
			TextWrapped = true,
			[React.Event.Activated] = if isLive
				then function()
					-- nothing comes back for a box that's empty, so only what was typed waits its turn
					local queue: { FieldDefinition } = {}
					for _, field in fields do
						if getText(state, field) ~= "" then
							table.insert(queue, field)
						end
					end
					queueRef.current = queue
					filterNext()
				end
				else nil,
		})
	end

	return e(React.Fragment, {}, children)
end
