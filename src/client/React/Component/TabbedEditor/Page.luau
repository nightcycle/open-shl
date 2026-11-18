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
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Components
local AssetList = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/AssetList")
-- Hooks
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local CharacterEditorTextFilterCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/TextFilterCallback")
local SetIsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetIsHeroFocus")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/Types")
type ArtInfo = Types.ArtInfo
type BarsInfo = Types.BarsInfo
type Box = Types.Box
type EditorState = CharacterEditorType.EditorState
type EntryInfo = Types.EntryInfo
type FieldDefinition = CharacterEditorType.FieldDefinition
type FieldEdit = CharacterEditorType.FieldEdit
type Focus = Types.Focus
type IconDefinition = MiscType.IconDefinition
type ListInfo = Types.ListInfo
type RowInfo = AssetList.RowInfo
type SlotsInfo = Types.SlotsInfo
type SwatchInfo = Types.SwatchInfo
type TabInfo = Types.TabInfo
type Tags = CharacterEditorUtil.Tags
type ToggleInfo = Types.ToggleInfo
type FieldCallback = (field: FieldDefinition, edit: FieldEdit) -> ()
-- an item a list offers: where its page is + how it's put on
type ItemEntry = {
	Path: string,
	DefinitionId: string,
	IsMulti: boolean,
	IsWorn: boolean,
	Toggle: FieldDefinition?,
}
-- a power a list offers + the field that holds it
type PowerEntry = {
	Id: string,
	Text: string,
	Icon: IconDefinition?,
	IsSelected: boolean,
	Field: FieldDefinition,
}
export type Properties = RobloxComponents.FrameProperties & {
	Tab: TabInfo,
	LimbIndex: number,
	OnFocus: (focus: Focus) -> (),
	OnLimbStep: () -> (),
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/CONSTANTS")
local ITEM_TAG: CharacterEditorType.Tag = "IsItemAdded"
local NO_FIELDS: { FieldDefinition } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getIfExcluded(tags: Tags, exclusionTags: { CharacterEditorType.Tag }?): boolean
	if exclusionTags then
		for _, exclusionTag: CharacterEditorType.Tag in exclusionTags do
			if tags[exclusionTag] then
				return true
			end
		end
	end
	return false
end

local function listPageFields(path: string): { FieldDefinition }
	local pageOpt = CharacterEditorDefinition.getPage(path)
	if pageOpt.IsNone then
		return NO_FIELDS
	end
	local fields: { FieldDefinition }? = pageOpt.Value.Fields
	return fields or NO_FIELDS
end

local function getPageTitle(path: string): string
	local pageOpt = CharacterEditorDefinition.getPage(path)
	if pageOpt.IsNone or pageOpt.Value.Type ~= "Default" then
		return path
	end
	return pageOpt.Value.Title or pageOpt.Value.Key
end

local function getItemName(definitionId: string): string
	local itemDefRes = AppearanceItemDefinition.get(definitionId)
	return if itemDefRes.IsOk then itemDefRes.Value.Name or definitionId else definitionId
end

local function listItems(state: EditorState, tags: Tags, folders: { string }): { ItemEntry }
	local out: { ItemEntry } = {}
	for _, folderPath in folders do
		local folderOpt = CharacterEditorDefinition.getPage(folderPath)
		if folderOpt.IsNone then
			continue
		end
		local folder = folderOpt.Value
		if folder.Type ~= "Default" or not folder.Children or getIfExcluded(tags, folder.ExclusionTags) then
			continue
		end
		for _, child in folder.Children do
			if child.Type ~= "Item" or getIfExcluded(tags, child.ExclusionTags) then
				continue
			end
			local toggle: FieldDefinition? = nil
			local fields: { FieldDefinition } = child.Fields or NO_FIELDS
			for _, field in fields do
				if field.Type == "Toggle" and field.Focus == ITEM_TAG then
					toggle = field
					break
				end
			end
			table.insert(out, {
				Path = CharacterEditorDefinition.getChildPath(folderPath, child),
				DefinitionId = child.DefinitionId,
				IsMulti = child.WearRule ~= "Single",
				IsWorn = CharacterEditorUtil.getIfItemWorn(state, child.DefinitionId),
				Toggle = toggle,
			})
		end
	end
	return out
end

local function listPowers(state: EditorState, path: string, list: ListInfo): { PowerEntry }
	local out: { PowerEntry } = {}
	local groups = list.PowerGroups
	if not groups then
		return out
	end
	for _, field in listPageFields(path) do
		if field.Type ~= "ChoiceList" or table.find(groups, field.Binding.Group) == nil then
			continue
		end
		local value = CharacterEditorUtil.read(state, field)
		for _, choice in field.Choices do
			table.insert(out, {
				Id = choice.Value,
				Text = if choice.Type == "Icon" then tostring(choice.Value) else choice.Text,
				Icon = if choice.Type == "Text" then nil else choice.Icon,
				IsSelected = value.Type == "Powers" and value.Powers[choice.Value] ~= nil,
				Field = field,
			})
		end
	end
	return out
end

-- the item a swatch colors: the one whose page is open, the first one that's worn otherwise
local function getSwatchPath(state: EditorState, tags: Tags, swatch: SwatchInfo, firstFolder: string?): string?
	if swatch.Page then
		return swatch.Page
	end
	local folders: { string } = if firstFolder then { firstFolder } else {}
	local swatchFolders: { string } = swatch.Folders or {}
	for _, folderPath in swatchFolders do
		table.insert(folders, folderPath)
	end
	local items = listItems(state, tags, folders)
	local path = CharacterEditorDefinition.fixPath(state.Path)
	for _, item in items do
		if item.Path == path then
			return item.Path
		end
	end
	for _, item in items do
		if item.IsWorn then
			return item.Path
		end
	end
	return nil
end

local function artLabel(props: {
	Art: ArtInfo,
	ZIndex: number,
})
	return e("ImageLabel", {
		BackgroundTransparency = 1,
		Image = props.Art.Image,
		Position = props.Art.Box.Position,
		Size = props.Art.Box.Size,
		ZIndex = props.ZIndex,
	})
end

-- a button with nothing to it but its picture
local function pictureButton(props: {
	Box: Box,
	Image: string,
	OnClick: (() -> ())?,
})
	return e("ImageButton", {
		Active = props.OnClick ~= nil,
		BackgroundTransparency = 1,
		Image = props.Image,
		Position = props.Box.Position,
		Size = props.Box.Size,
		ZIndex = 4,
		[React.Event.Activated] = props.OnClick,
	})
end

local function bars(props: {
	Info: BarsInfo,
	State: EditorState,
	OnPick: FieldCallback,
}): React.ReactNode
	local style = React.useContext(StyleContext)
	local info = props.Info
	local field: FieldDefinition? = nil
	for _, pageField in listPageFields(info.Page) do
		if pageField.Type == "Choose" and pageField.Binding.Type == "Scale" and pageField.Binding.Axis == info.Axis then
			field = pageField
			break
		end
	end
	if not field or field.Type ~= "Choose" then
		return nil
	end
	local chooseField = field
	local value = CharacterEditorUtil.read(props.State, chooseField)
	local picked: number? = if value.Type == "Choice" and type(value.Value) == "number" then value.Value else nil
	local buttons: { [string]: React.ReactNode } = {}
	for index, barBox in info.Boxes do
		local choice = chooseField.Choices[index]
		if not choice or type(choice.Value) ~= "number" then
			continue
		end
		-- every bar up to the picked one is filled in, a width went through a division on its way here
		local isFilled = picked ~= nil and choice.Value <= picked + CharacterEditorDefinition.SCALE_EPSILON
		buttons[`Bar-{index}`] = e("ImageButton", {
			BackgroundColor3 = style.Palette.AccentLight,
			BackgroundTransparency = if isFilled then 0 else 1,
			BorderSizePixel = 0,
			Position = barBox.Position,
			Size = barBox.Size,
			ZIndex = 4,
			[React.Event.Activated] = function()
				props.OnPick(chooseField, {
					Type = "Choice",
					Value = choice.Value,
				})
			end,
		})
	end
	return e(React.Fragment, {}, buttons)
end

local function entry(props: {
	Info: EntryInfo,
	State: EditorState,
	OnEdit: FieldCallback,
}): React.ReactNode
	local style = React.useContext(StyleContext)
	local setIsHeroFocus = React.useContext(SetIsHeroFocusContext)
	local setPath = React.useContext(SetPathContext)
	local filterText = React.useContext(CharacterEditorTextFilterCallback)
	local info, state = props.Info, props.State
	local field: FieldDefinition? = nil
	for _, pageField in listPageFields(info.Page) do
		if pageField.Type == "Text" then
			field = pageField
			break
		end
	end
	if not field or field.Type ~= "Text" then
		return nil
	end
	local textField = field
	local identityKey = info.IdentityKey or state.IdentityKey
	local identity = state.Character.Identities[identityKey]
	if not identity then
		return nil
	end
	local text = if textField.Binding.Key == "Name" then identity.Profile.Name else identity.Profile.Backstory
	-- what's typed goes to the identity in front, so the one the box belongs to steps forward first
	local function focus()
		if identityKey ~= state.IdentityKey and setIsHeroFocus then
			setIsHeroFocus(identityKey == "Main")
		end
	end
	return e(
		"TextBox",
		{
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			FontFace = style.Fonts.Body,
			MultiLine = textField.IsMultiLine == true,
			PlaceholderColor3 = info.PlaceholderColor3,
			PlaceholderText = textField.Description,
			Position = info.Box.Position,
			Size = info.Box.Size,
			Text = text,
			TextColor3 = info.TextColor3,
			TextScaled = info.TextSize == nil,
			TextSize = info.TextSize,
			TextWrapped = true,
			ZIndex = 4,
			[React.Change.Text] = function(textBox: TextBox)
				local typedText = textBox.Text
				local length = utf8.len(typedText)
				-- only what the player types is an edit, the box is also written to when the draft changes
				if typedText == text or not length or not textBox:IsFocused() then
					return
				end
				local maxLength = textField.MaxLength
				if maxLength and length > maxLength then
					local endIndex = utf8.offset(typedText, math.max(0, math.floor(maxLength)) + 1)
					typedText = string.sub(typedText, 1, (endIndex or (#typedText + 1)) - 1)
					textBox.Text = typedText
				end
				focus()
				props.OnEdit(textField, {
					Type = "Text",
					Text = typedText,
				})
			end,
			-- a text is run through the filter as soon as it's let go of
			[React.Event.FocusLost] = function()
				if not setPath or not filterText then
					return
				end
				focus()
				setPath(info.Page)
				filterText(textField)
			end,
		} :: RobloxComponents.TextBoxProperties
	)
end

local function slots(props: {
	Info: SlotsInfo,
	Powers: { PowerEntry },
	State: EditorState,
	OnEdit: FieldCallback,
})
	local info, state = props.Info, props.State
	local buttons: { [string]: React.ReactNode } = {}
	for index = 1, PowerDefinition.PASS_LIMIT do
		local held = state.Character.Powers[index]
		local power: PowerEntry? = nil
		for _, powerEntry in props.Powers do
			if held and powerEntry.Id == held.Id then
				power = powerEntry
				break
			end
		end
		local icon = if power then power.Icon else nil
		local isLocked = index > state.Entitlements.PowerLimit
		-- the ring of a slot is a little larger than what sits in it
		buttons[`Slot-{index}`] = e("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Size = UDim2.fromScale(info.SlotSize, info.SlotSize),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Art = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = CONSTANTS.SLOT_ART,
				ImageColor3 = if isLocked then CONSTANTS.LOCKED_SLOT_COLOR else Color3.new(1, 1, 1),
				ImageTransparency = if isLocked then CONSTANTS.LOCKED_SLOT_TRANSPARENCY else 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(CONSTANTS.SLOT_ART_SIZE, CONSTANTS.SLOT_ART_SIZE),
			}),
			Icon = e("ImageButton", {
				BackgroundTransparency = 1,
				Image = if not icon then "" elseif icon.Type == "Sprite" then icon.SheetUrl else icon.Url,
				ImageRectOffset = if icon and icon.Type == "Sprite" then icon.Position else nil,
				ImageRectSize = if icon and icon.Type == "Sprite" then icon.Size else nil,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				-- a press on a slot empties it
				[React.Event.Activated] = function()
					if power then
						props.OnEdit(power.Field, {
							Type = "Power",
							Id = power.Id,
							IsSelected = false,
						})
					end
				end,
			}),
		})
	end
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = info.Box.Position,
		Size = info.Box.Size,
		ZIndex = 4,
	}, {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(info.Padding, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
			PaddingTop = UDim.new(0, 5),
		}),
		Buttons = e(React.Fragment, {}, buttons),
	})
end
-- Class
-- one page of the editor: its picture, the tags over the headings of the picture + the controls the picture leaves
-- room for, each of them bound to a page of the game's editor
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local state = React.useContext(CharacterEditorStateContext)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	local setPath = React.useContext(SetPathContext)
	local tab = props.Tab
	if not state or not fieldCallback or not setPath then
		return nil
	end
	local tags = CharacterEditorUtil.getTags(state)
	local openPath = CharacterEditorDefinition.fixPath(state.Path)

	-- a row puts its item on, the row of what's worn takes it off again. where several are worn at once a worn one
	-- is opened first, so it can be colored without taking it off
	local function pressItem(item: ItemEntry)
		local toggle = item.Toggle
		local isOpen = item.Path == openPath
		if not toggle then
			return
		end
		if not item.IsWorn then
			setPath(item.Path)
			fieldCallback(toggle, {
				Type = "Toggle",
				IsSelected = true,
			})
		elseif item.IsMulti and not isOpen then
			setPath(item.Path)
		else
			setPath(item.Path)
			fieldCallback(toggle, {
				Type = "Toggle",
				IsSelected = false,
			})
			-- its page would go on showing it as something that's tried on
			setPath("")
		end
	end

	local children: { [string]: React.ReactNode } = {}
	children.Art = e(artLabel, {
		Art = {
			Image = tab.Art,
			Box = CONSTANTS.PAGE_ART_BOX,
		},
		ZIndex = 1,
	})
	local sidebars: { ArtInfo } = tab.Sidebars or {}
	for index, sidebar in sidebars do
		children[`Sidebar-{index}`] = e(artLabel, {
			Art = sidebar,
			ZIndex = 2,
		})
	end
	if tab.Logo then
		children.Logo = e(artLabel, {
			Art = tab.Logo,
			ZIndex = 2,
		})
	end
	for index, heading in tab.Headings do
		children[`Heading-{index}`] = e("TextLabel", {
			BackgroundColor3 = style.Palette.Field,
			BorderSizePixel = 0,
			FontFace = style.Fonts.Heading,
			Position = heading.Box.Position,
			Size = heading.Box.Size,
			Text = heading.Text,
			TextColor3 = heading.TextColor3 or style.Palette.Accent,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = 3,
		})
	end

	local limbFolder: string? = nil
	local powers: { PowerEntry } = {}
	local lists: { ListInfo } = tab.Lists or {}
	for index, list in lists do
		local rows: { RowInfo } = {}
		local folders = list.Folders
		if list.Limbs then
			limbFolder = list.Limbs[(props.LimbIndex - 1) % #list.Limbs + 1]
			folders = { limbFolder :: string }
		end
		if folders then
			for _, item in listItems(state, tags, folders) do
				table.insert(rows, {
					Key = item.DefinitionId,
					Text = getItemName(item.DefinitionId),
					IsSelected = item.IsWorn,
					OnClick = function()
						pressItem(item)
					end,
				})
			end
		elseif tab.Path then
			for _, power in listPowers(state, tab.Path, list) do
				table.insert(powers, power)
				table.insert(rows, {
					Key = power.Id,
					Text = power.Text,
					IsSelected = power.IsSelected,
					OnClick = function()
						fieldCallback(power.Field, {
							Type = "Power",
							Id = power.Id,
							IsSelected = not power.IsSelected,
						})
					end,
				})
			end
		end
		-- keyed by what it lists, so the list of another limb starts at its top
		children[`List-{index}-{limbFolder or ""}`] = e(
			AssetList,
			{
				Position = list.Box.Position,
				Size = list.Box.Size,
				ZIndex = 3,
				Rows = rows,
			} :: AssetList.Properties
		)
	end

	local swatches: { SwatchInfo } = tab.Swatches or {}
	for index, swatch in swatches do
		local swatchPath = getSwatchPath(state, tags, swatch, limbFolder)
		children[`Swatch-{index}`] = e(pictureButton, {
			Box = swatch.Box,
			Image = swatch.Image,
			-- there's nothing to color while nothing of its kind is worn
			OnClick = if swatchPath
				then function()
					props.OnFocus({
						Path = swatchPath,
						Group = swatch.Group,
					})
				end
				else nil,
		})
	end

	local toggles: { ToggleInfo } = tab.Toggles or {}
	for index, toggle in toggles do
		local field: FieldDefinition? = nil
		for _, pageField in listPageFields(toggle.Page) do
			if pageField.Type == "Toggle" then
				field = pageField
				break
			end
		end
		if not field then
			continue
		end
		local toggleField = field
		local value = CharacterEditorUtil.read(state, toggleField)
		local isSelected = value.Type == "Toggle" and value.IsSelected
		children[`Toggle-{index}`] = e(pictureButton, {
			Box = toggle.Box,
			Image = if isSelected then toggle.SelectedImage else toggle.Image,
			OnClick = function()
				fieldCallback(toggleField, {
					Type = "Toggle",
					IsSelected = not isSelected,
				})
			end,
		})
	end

	local barRows: { BarsInfo } = tab.Bars or {}
	for index, barsInfo in barRows do
		children[`Bars-{index}`] = e(bars, {
			Info = barsInfo,
			State = state,
			OnPick = fieldCallback,
		})
	end
	local entries: { EntryInfo } = tab.Entries or {}
	for index, entryInfo in entries do
		children[`Entry-{index}`] = e(entry, {
			Info = entryInfo,
			State = state,
			OnEdit = fieldCallback,
		})
	end
	if tab.Slots then
		children.Slots = e(slots, {
			Info = tab.Slots,
			Powers = powers,
			State = state,
			OnEdit = fieldCallback,
		})
	end

	local application = tab.Application
	if application and limbFolder then
		children.ApplicationArt = e(artLabel, {
			Art = application.Art,
			ZIndex = 2,
		})
		-- names the limb the list holds the pieces of, a press steps to the next one
		children.Application = e("TextButton", {
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = application.Box.Position,
			Size = application.Box.Size,
			Text = getPageTitle(limbFolder),
			TextColor3 = CONSTANTS.APPLICATION_TEXT_COLOR,
			TextSize = CONSTANTS.APPLICATION_TEXT_SIZE,
			TextWrapped = true,
			ZIndex = 4,
			[React.Event.Activated] = props.OnLimbStep,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		} :: RobloxComponents.FrameProperties,
		props,
		children
	))
end
