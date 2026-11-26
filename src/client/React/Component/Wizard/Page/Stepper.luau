--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
local Gate = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Page/Gate")
-- Components
local Row = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Row")
-- Hooks
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Types")
type ChoiceDefinition = MiscType.ChoiceDefinition
type EditorState = CharacterEditorType.EditorState
type FieldDefinition = CharacterEditorType.FieldDefinition
type PatternChoice = CharacterEditorType.PatternChoice
type RowInfo = Types.RowInfo
-- something of a list a row steps to: where its page is, the field that puts it on + how much of it is worn already
type Entry = {
	Path: string,
	Name: string,
	Toggle: FieldDefinition,
	WornCount: number,
	DefinitionIds: { string },
}
export type Properties = {
	Row: RowInfo,
	PageKey: string, -- the page of the game's editor the row is on
	IsLive: boolean?, -- left out, the row is only looked at
	IsPeaceful: boolean?, -- what a row of the mode reads
	OnPeaceful: ((isPeaceful: boolean) -> ())?,
	Hold: Gate.Hold?, -- what the draft is short of. left out, nothing is held back
	OnPurchase: ((id: string) -> ())?, -- asks for what opens an item or a power, by its id
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/CONSTANTS")
local ITEM_TAG: CharacterEditorType.Tag = "IsItemAdded"
local NO_FIELDS: { FieldDefinition } = table.freeze({})
local NO_PATTERN_CHOICES: { PatternChoice } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function findToggle(pageFields: { FieldDefinition }?): FieldDefinition?
	local fields: { FieldDefinition } = pageFields or NO_FIELDS
	for _, field in fields do
		if field.Type == "Toggle" and field.Focus == ITEM_TAG then
			return field
		end
	end
	return nil
end

-- what a list of the game's editor holds, in its order. a place built for another game has no such list
local function listEntries(state: EditorState, folderPath: string): { Entry }
	local out: { Entry } = {}
	local folderOpt = CharacterEditorDefinition.getPage(folderPath)
	if folderOpt.IsNone then
		return out
	end
	local folder = folderOpt.Value
	if folder.Type ~= "Default" or not folder.Children then
		return out
	end
	for _, child in folder.Children do
		if child.Type == "Item" then
			local toggle = findToggle(child.Fields)
			local itemDefRes = AppearanceItemDefinition.get(child.DefinitionId)
			if toggle then
				table.insert(out, {
					Path = CharacterEditorDefinition.getChildPath(folderPath, child),
					Name = if itemDefRes.IsOk and itemDefRes.Value.Name
						then itemDefRes.Value.Name
						else child.DefinitionId,
					Toggle = toggle,
					WornCount = if CharacterEditorUtil.getIfItemWorn(state, child.DefinitionId) then 1 else 0,
					DefinitionIds = { child.DefinitionId },
				})
			end
		elseif child.Type == "Set" then
			local toggle = findToggle(child.Fields)
			local wornCount = 0
			for _, definitionId in child.DefinitionIds do
				if CharacterEditorUtil.getIfItemWorn(state, definitionId) then
					wornCount += 1
				end
			end
			if toggle then
				table.insert(out, {
					Path = CharacterEditorDefinition.getChildPath(folderPath, child),
					Name = child.Title or child.Key,
					Toggle = toggle,
					WornCount = wornCount,
					DefinitionIds = child.DefinitionIds,
				})
			end
		end
	end
	return out
end

-- where a list stands: at what's worn of it. of a list of sets that's the set most of what's worn is of, so a suit
-- that had a piece swapped is still the one the row steps on from
local function findWornIndex(entries: { Entry }): number?
	local wornIndex: number? = nil
	local wornCount = 0
	for index, entry in entries do
		if entry.WornCount > wornCount then
			wornIndex = index
			wornCount = entry.WornCount
		end
	end
	return wornIndex
end

-- the one after the last is the first again. with nothing to step on from either arrow starts at its own end
local function getNextIndex(index: number?, count: number, direction: number): number
	return if index then (index - 1 + direction) % count + 1 elseif direction > 0 then 1 else count
end

local function getChoiceText(choice: ChoiceDefinition): string
	return if choice.Type == "Icon" then tostring(choice.Value) else choice.Text
end
-- Class
-- a row of a page with what its arrows do to the draft: it steps through a list of the page of the game's editor it's
-- on, or through the choices of one of that page's fields. what a row can't find in the game the place is built for
-- it has nothing to step through, the bar is there all the same
local function stepper(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local state = React.useContext(CharacterEditorStateContext)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local setPath = React.useContext(SetPathContext)
	local row = props.Row
	local source = row.Source
	if not state or not fieldCallback or not setPath then
		return nil
	end
	local palette = style.Palette
	local hold = props.Hold

	local text = row.Text
	local onStep: ((direction: number) -> ())? = nil
	local under: { [string]: React.ReactNode } = {}
	if source.Type == "Items" or source.Type == "Sets" then
		local entries = listEntries(state, source.Folder)
		local hasNone = source.Type == "Items" and source.HasNone == true
		local isPassingLocked = source.Type == "Items" and source.IsPassingLocked == true
		-- an entry the arrows of the row don't stop on: something of it is held back from the player
		local function getIfPassed(entry: Entry): boolean
			if hold and isPassingLocked then
				for _, definitionId in entry.DefinitionIds do
					if Gate.getIfShort(hold, state, definitionId) then
						return true
					end
				end
			end
			return false
		end
		onStep = function(direction: number)
			if #entries == 0 then
				return
			end
			local wornIndex = findWornIndex(entries)
			-- a list with a stop for nothing has it between its last item + its first: stepped to, what's worn of the
			-- list comes off. with nothing worn the row stands on that stop
			local isLeaving = hasNone and wornIndex == (if direction > 0 then #entries else 1)
			local index = if isLeaving and wornIndex then wornIndex else getNextIndex(wornIndex, #entries, direction)
			if not isLeaving then
				-- on to the next the row stops on. where it stops on none of them the arrow does nothing
				local passedCount = 0
				while getIfPassed(entries[index]) do
					passedCount += 1
					if passedCount == #entries then
						return
					end
					index = getNextIndex(index, #entries, direction)
				end
			end
			local entry = entries[index]
			-- a field of an item or a set is written through its page
			setPath(entry.Path)
			fieldCallback(entry.Toggle, {
				Type = "Toggle",
				IsSelected = not isLeaving,
			})
		end
	elseif source.Type == "Extras" then
		local entries = listEntries(state, source.Folder)
		-- the one that's tried on or was last kept is the one whose page is open
		local openIndex: number? = nil
		for index, entry in entries do
			if entry.Path == state.Path then
				openIndex = index
			end
		end
		local openEntry: Entry? = if openIndex then entries[openIndex] else nil
		local isKept = openEntry ~= nil and openEntry.WornCount > 0
		onStep = function(direction: number)
			if #entries > 0 then
				setPath(entries[getNextIndex(openIndex, #entries, direction)].Path)
			end
		end
		under.Box = e("Frame", {
			BackgroundColor3 = palette.FieldAlt,
			BackgroundTransparency = CONSTANTS.NESTED_ROW_TRANSPARENCY,
			BorderSizePixel = 0,
			Position = CONSTANTS.EXTRAS_BOX_POSITION,
			Size = CONSTANTS.EXTRAS_BOX_SIZE,
		}, {
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Position = CONSTANTS.EXTRAS_LABEL_POSITION,
				Size = CONSTANTS.EXTRAS_LABEL_SIZE,
				Text = if openEntry then openEntry.Name else CONSTANTS.NONE_TEXT,
				TextColor3 = palette.Text,
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Button = e("TextButton", {
				Active = props.IsLive == true,
				BackgroundColor3 = if isKept then palette.Negative else palette.Positive,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Body,
				Position = CONSTANTS.EXTRAS_BUTTON_POSITION,
				Size = CONSTANTS.EXTRAS_BUTTON_SIZE,
				Text = if isKept then CONSTANTS.EXTRAS_REMOVE_TEXT else CONSTANTS.EXTRAS_ADD_TEXT,
				TextColor3 = palette.Text,
				TextScaled = true,
				TextWrapped = true,
				[React.Event.Activated] = if props.IsLive and openEntry
					then function()
						fieldCallback(openEntry.Toggle, {
							Type = "Toggle",
							IsSelected = not isKept,
						})
					end
					else nil,
			}),
		})
	elseif source.Type == "Glow" then
		local field = Gate.findField(props.PageKey, "Pattern", source.Field)
		local choices: { PatternChoice } = CharacterEditorDefinition.PATTERN_CHOICES or NO_PATTERN_CHOICES
		if field and #choices > 0 then
			local value = CharacterEditorUtil.read(state, field)
			-- what's worn of nothing reads like the first of the looks
			local index = 1
			for choiceIndex, choice in choices do
				if
					value.Type == "Pattern"
					and choice.Material == value.Material
					and choice.Pattern == value.Pattern
				then
					index = choiceIndex
				end
			end
			onStep = function(direction: number)
				local choice = choices[getNextIndex(index, #choices, direction)]
				fieldCallback(field, {
					Type = "Pattern",
					Material = choice.Material,
					Pattern = choice.Pattern,
				})
			end
		end
	elseif source.Type == "Power" then
		local field = Gate.findField(props.PageKey, "ChoiceList", source.Field)
		local pickedText: string? = nil
		if field and field.Type == "ChoiceList" then
			local choices = field.Choices
			local value = CharacterEditorUtil.read(state, field)
			local index: number? = nil
			for choiceIndex, choice in choices do
				if value.Type == "Powers" and value.Powers[choice.Value] then
					index = choiceIndex
					pickedText = getChoiceText(choice)
				end
			end
			onStep = function(direction: number)
				if #choices == 0 then
					return
				end
				fieldCallback(field, {
					Type = "Power",
					Id = choices[getNextIndex(index, #choices, direction)].Value,
					IsSelected = true,
				})
			end
		end
		under.Assignment = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = CONSTANTS.ASSIGNMENT_POSITION,
			Size = CONSTANTS.ASSIGNMENT_SIZE,
			Text = pickedText or CONSTANTS.NONE_TEXT,
			TextColor3 = palette.TextStrong,
			TextScaled = true,
			TextWrapped = true,
		})
	elseif source.Type == "Choice" then
		local field = Gate.findField(props.PageKey, "Choose", source.Field)
		if field and field.Type == "Choose" then
			local choices = field.Choices
			local value = CharacterEditorUtil.read(state, field)
			local index: number? = nil
			for choiceIndex, choice in choices do
				if value.Type == "Choice" and choice.Value == value.Value then
					index = choiceIndex
					text = getChoiceText(choice)
				end
			end
			onStep = function(direction: number)
				if #choices == 0 then
					return
				end
				fieldCallback(field, {
					Type = "Choice",
					Value = choices[getNextIndex(index, #choices, direction)].Value,
				})
			end
		end
	else
		local isPeaceful = props.IsPeaceful == true
		local onPeaceful = props.OnPeaceful
		text = if isPeaceful then CONSTANTS.PEACEFUL_MODE_TEXT else CONSTANTS.MODE_TEXT
		-- there are two of them, so either arrow is the switch
		onStep = if onPeaceful
			then function()
				onPeaceful(not isPeaceful)
			end
			else nil
	end

	local rows: { RowInfo } = row.Rows or {}
	for _, nestedRow in rows do
		under[`Row-{nestedRow.Text}`] = e(stepper, {
			Row = nestedRow,
			PageKey = props.PageKey,
			IsLive = props.IsLive,
			Hold = hold,
			OnPurchase = props.OnPurchase,
		})
	end

	-- while what the row has on is held back it says so in place of its name. behind a pass a press on that is how
	-- the pass is asked for, what's for the group has nothing to press
	local heldId: string?, heldListing: Gate.Listing? = nil, nil
	if hold then
		heldId, heldListing = Gate.getHeld(hold, state, props.PageKey, row)
	end
	local lock = if heldListing then heldListing.Lock else nil
	local onPurchase = props.OnPurchase
	local onName: (() -> ())? = nil
	if lock then
		text = if lock.Type == "GroupPerk" then CONSTANTS.GATE_GROUP_TEXT else CONSTANTS.GATE_PASS_TEXT
		if lock.Type == "Entitlement" and heldId and onPurchase and props.IsLive then
			local id: string = heldId
			onName = function()
				onPurchase(id)
			end
		end
	end

	return e(
		Row,
		{
			BackgroundColor3 = if row.IsNested then palette.FieldAlt else nil,
			BackgroundTransparency = if row.IsNested then CONSTANTS.NESTED_ROW_TRANSPARENCY else nil,
			Position = row.Position,
			Size = row.Size,
			Text = text,
			NameColor3 = if lock then CONSTANTS.GATE_COLOR else nil,
			LeftPosition = CONSTANTS.ROW_LEFT_POSITION,
			RightPosition = CONSTANTS.ROW_RIGHT_POSITION,
			ArrowSize = CONSTANTS.ROW_ARROW_SIZE,
			NamePosition = CONSTANTS.ROW_NAME_POSITION,
			NameSize = CONSTANTS.ROW_NAME_SIZE,
			OnStep = if props.IsLive then onStep else nil,
			OnName = onName,
			Under = under,
		} :: Row.Properties
	)
end
return stepper
