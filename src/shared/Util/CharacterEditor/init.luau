--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AliasDefinition = require("@game/ReplicatedStorage/Shared/Definition/Alias")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemUtil = require("@self/Item")
local PageUtil = require("@self/Page")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local PowerUtil = require("@self/Power")
local ProfileUtil = require("@self/Profile")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local StateUtil = require("@self/State")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
export type EditorState = CharacterEditorType.EditorState
export type Entitlements = CharacterEditorType.Entitlements
export type FieldDefinition = CharacterEditorType.FieldDefinition
export type PageDefinition = CharacterEditorType.PageDefinition
export type FieldValue = CharacterEditorType.FieldValue
export type FieldEdit = CharacterEditorType.FieldEdit
export type Tag = CharacterEditorType.Tag
export type Tags = PageUtil.Tags
export type Character = CharacterType.Character
export type IdentityKey = CharacterType.IdentityKey
type ItemTextureBinding = CharacterEditorType.ItemTextureBinding
type Identity = IdentityType.Identity
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
type HiddenTag = AppearanceType.HiddenTag
type TransitionType = AppearanceType.TransitionType
type Preview = {
	Appearance: Appearance, -- what the scene dresses the rig in
	PendingItem: Item?,
	DefinitionId: string?, -- the item of the open page
	HasMultiHair: boolean,
}
-- Constants
local DETAIL_TEXTURE_GROUP_KEY: TextureGroupKey = CharacterEditorDefinition.DETAIL_TEXTURE_GROUP_KEY :: TextureGroupKey
-- a header bound to the power limit spells the limit out
local NUMBER_WORDS: { string } = table.freeze({ "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight" })
-- Variables
-- the scene re-dresses the rig on a new appearance table, so a state keeps the very same preview
local PreviewCache: { [EditorState]: Character } = {}
setmetatable(PreviewCache, { __mode = "k" })
-- an edit that doesn't show still makes a new state, its preview stays the same table as well
local PreviewAppearanceCache: { [Appearance]: Preview } = {}
setmetatable(PreviewAppearanceCache, { __mode = "k" })
-- References
-- Private Functions
local function getTransitionStyle(appearance: Appearance, transitionType: TransitionType): string
	if transitionType == "Death" then
		local transition = appearance.Transitions.Death
		return if transition then transition.Style else TransitionDefinition.DEFAULT_DEATH_STYLE
	end
	local transition = appearance.Transitions.Transformation
	return if transition then transition.Style else TransitionDefinition.DEFAULT_TRANSFORMATION_STYLE
end

local function setTransitionStyle(
	state: EditorState,
	transitionType: TransitionType,
	value: unknown
): Result<EditorState, string>
	local isDeath = transitionType == "Death"
	local isValid = if isDeath
		then AppearanceType.DeathTransition({ Style = value })
		else AppearanceType.TransformationTransition({ Style = value })
	if not isValid then
		return Result.err(`"{tostring(value)}" isn't a {if isDeath then "death" else "transformation"} style`)
	end
	return Result.ok(StateUtil.editIdentities(state, function(identity: Identity): Identity
		-- picking the default stores it like any other style
		local transitions = identity.Appearance.Transitions
		local transition: AppearanceType.Transition? = if isDeath then transitions.Death else transitions.Transformation
		if transition and transition.Style == value then
			return identity
		end
		-- a style isn't worn, the items + hidden tags next to it stay the very same tables so a scene can tell
		local editedTransitions = table.clone(transitions)
		if isDeath then
			editedTransitions.Death = table.freeze({ Style = value :: PseudoEnum.DeathStyle })
		else
			editedTransitions.Transformation = table.freeze({ Style = value :: PseudoEnum.TransformationStyle })
		end
		table.freeze(editedTransitions)
		local appearance = table.clone(identity.Appearance)
		appearance.Transitions = editedTransitions
		table.freeze(appearance)
		return StateUtil.setAppearance(identity, appearance)
	end))
end

local function setSkinColor(state: EditorState, color: Color3): Result<EditorState, string>
	local appearance = StateUtil.getIdentity(state).Appearance
	if appearance.SkinColor == color then
		return Result.ok(state)
	end
	return Result.ok(
		StateUtil.setFocusedAppearance(
			state,
			FreezeUtil.delta(appearance, function(t: Appearance): Appearance
				t.SkinColor = color
				return t
			end)
		)
	)
end

local function getItemTexture(state: EditorState, binding: ItemTextureBinding): TextureGroup?
	local itemDef = PageUtil.getItemDefinition(state)
	local key: TextureGroupKey? = if itemDef then ItemUtil.getTextureGroupKey(state, itemDef, binding) else nil
	if not itemDef or not key then
		return nil
	end
	local groupRes = ItemUtil.getTextureGroup(state, itemDef.Id, key)
	return if groupRes.IsOk then groupRes.Value else nil
end

local function setItemTexture(
	state: EditorState,
	binding: ItemTextureBinding,
	fn: (group: TextureGroup) -> TextureGroup
): Result<EditorState, string>
	local itemDef = PageUtil.getItemDefinition(state)
	if not itemDef then
		return Result.err(`no item is selected`)
	end
	local key: TextureGroupKey? = ItemUtil.getTextureGroupKey(state, itemDef, binding)
	if not key then
		return Result.err(`"{ItemUtil.getName(itemDef.Id)}" has nothing to change there`)
	end
	return ItemUtil.setTextureGroup(state, itemDef, key, fn)
end

local function getIfFiltered<V>(filtered: { V }?, value: V): boolean
	return filtered ~= nil and table.find(filtered, value) ~= nil
end

local function getPreviewCharacter(state: EditorState): Character
	local cachedCharacter = PreviewCache[state]
	if cachedCharacter then
		return cachedCharacter
	end
	local identity = StateUtil.getIdentity(state)
	local itemDef = PageUtil.getItemDefinition(state)
	local pendingItem = state.PendingItem
	local hiddenTags: { HiddenTag } = {}
	for _, hiddenTag in identity.Appearance.HiddenTags do
		if not itemDef or table.find(itemDef.Tags, hiddenTag) == nil then
			table.insert(hiddenTags, hiddenTag)
		end
	end
	if not pendingItem and #hiddenTags == #identity.Appearance.HiddenTags then
		return state.Character
	end
	local definitionId: string? = if itemDef then itemDef.Id else nil
	local hasMultiHair = state.Entitlements.HasMultiHair
	local cachedPreview = PreviewAppearanceCache[identity.Appearance]
	local appearance: Appearance
	if
		cachedPreview
		and cachedPreview.PendingItem == pendingItem
		and cachedPreview.DefinitionId == definitionId
		and cachedPreview.HasMultiHair == hasMultiHair
	then
		appearance = cachedPreview.Appearance
	else
		appearance = FreezeUtil.delta(identity.Appearance, function(t: Appearance): Appearance
			if pendingItem then
				ItemUtil.removeReplaced(state, t.Items, pendingItem.DefinitionId)
				table.insert(t.Items, pendingItem)
			end
			t.HiddenTags = hiddenTags
			return t
		end)
		PreviewAppearanceCache[identity.Appearance] = table.freeze({
			Appearance = appearance,
			PendingItem = pendingItem,
			DefinitionId = definitionId,
			HasMultiHair = hasMultiHair,
		})
	end
	local previewCharacter =
		StateUtil.setIdentity(state.Character, state.IdentityKey, StateUtil.setAppearance(identity, appearance))
	PreviewCache[state] = previewCharacter
	return previewCharacter
end

-- the draft takes the very appearance the scene has so the rig isn't dressed all over again
local function addItem(state: EditorState, definitionId: string): Result<EditorState, string>
	local stateRes = ItemUtil.add(state, definitionId)
	if stateRes.IsErr or stateRes.Value == state then
		return stateRes
	end
	local previewCharacter = getPreviewCharacter(state)
	local shownIdentity = previewCharacter.Identities[state.IdentityKey] or previewCharacter.Identities.Main
	local shownAppearance = shownIdentity.Appearance
	local wornAppearance = StateUtil.getIdentity(stateRes.Value).Appearance
	if shownAppearance == wornAppearance or not StateUtil.getIfEqual(shownAppearance, wornAppearance) then
		return stateRes
	end
	return Result.ok(StateUtil.setFocusedAppearance(stateRes.Value, shownAppearance))
end

-- Class
local Util = {}

function Util.getTags(state: EditorState): Tags
	local tags: Tags = {}
	tags[PageUtil.getIdentityTag(state.IdentityKey)] = true
	local hasLenses = false
	local itemDef = PageUtil.getItemDefinition(state)
	if itemDef then
		if ItemUtil.find(StateUtil.getIdentity(state).Appearance, itemDef.Id) then
			tags["IsItemAdded" :: Tag] = true
		end
		hasLenses = ItemUtil.getIfLensesShown(state, itemDef)
		if state.FocusedGroup == DETAIL_TEXTURE_GROUP_KEY then
			local focusTag: Tag = if ItemUtil.getIfLensItem(itemDef) then "IsLensFocused" else "IsEdgeFocused"
			tags[focusTag] = true
		end
	end
	local lensTag: Tag = if hasLenses then "HasLenses" else "HasNoLenses"
	tags[lensTag] = true
	table.freeze(tags)
	return tags
end

function Util.getIfExcluded(state: EditorState, exclusionTags: { Tag }?): boolean
	return PageUtil.getIfExcluded(Util.getTags(state), exclusionTags)
end

function Util.getIfItemWorn(state: EditorState, definitionId: string): boolean
	return ItemUtil.find(StateUtil.getIdentity(state).Appearance, definitionId) ~= nil
end

function Util.listPages(state: EditorState): { PageDefinition }
	local out: { PageDefinition } = {}
	local folderOpt = CharacterEditorDefinition.findFirstFolderPage(state.Path)
	if folderOpt.IsSome and folderOpt.Value.Type == "Default" and folderOpt.Value.Children then
		local tags = Util.getTags(state)
		for _, page in folderOpt.Value.Children do
			if not PageUtil.getIfExcluded(tags, page.ExclusionTags) then
				table.insert(out, page)
			end
		end
	end
	table.freeze(out)
	return out
end

function Util.listFields(state: EditorState): { FieldDefinition }
	local out: { FieldDefinition } = {}
	local page = PageUtil.get(state.Path)
	if page and page.Fields then
		local tags = Util.getTags(state)
		local function insertFields(fields: { FieldDefinition })
			for _, field in fields do
				if PageUtil.getIfExcluded(tags, field.ExclusionTags) then
					continue
				end
				table.insert(out, field)
				if field.Type == "Toggle" then
					local sections = if tags[field.Focus] then field.Sections else field.DisabledSections
					if sections then
						insertFields(sections)
					end
				end
			end
		end
		insertFields(page.Fields)
	end
	table.freeze(out)
	return out
end

-- an item page tries its item on when it isn't worn, a closed or missing page leads back to the root
function Util.setPath(state: EditorState, path: string): EditorState
	path = CharacterEditorDefinition.fixPath(path)
	local page = PageUtil.get(path)
	if not page or PageUtil.getIfClosed(state.IdentityKey, path) then
		path = ""
		page = nil
	end
	if path == state.Path then
		return state
	end
	local pendingItem: Item? = nil
	if page and page.Type == "Item" and not Util.getIfItemWorn(state, page.DefinitionId) then
		pendingItem = ItemUtil.newPending(state, page.DefinitionId)
	end
	return StateUtil.delta(state, function(t: EditorState)
		t.Path = path
		t.PendingItem = pendingItem
		t.FocusedGroup = nil
	end)
end

-- the page stays open when that identity has it too, what was tried on doesn't come along
function Util.setIdentityKey(state: EditorState, identityKey: IdentityKey): EditorState
	if identityKey == state.IdentityKey then
		return state
	end
	return Util.setPath(
		StateUtil.delta(state, function(t: EditorState)
			t.IdentityKey = identityKey
			t.Path = ""
			t.PendingItem = nil
			t.FocusedGroup = nil
		end),
		state.Path
	)
end

function Util.setEntitlements(state: EditorState, entitlements: Entitlements): EditorState
	if StateUtil.getIfEqual(state.Entitlements, entitlements) then
		return state
	end
	return StateUtil.delta(state, function(t: EditorState)
		t.Entitlements = table.freeze(table.clone(entitlements))
	end)
end

function Util.setTag(state: EditorState, tag: Tag, isSelected: boolean): Result<EditorState, string>
	if tag == "IsSuper" or tag == "IsSecret" then
		local isSuper = (tag == "IsSuper") == isSelected
		return Result.ok(Util.setIdentityKey(state, if isSuper then "Main" else "Secret"))
	end
	local itemDef = PageUtil.getItemDefinition(state)
	if not itemDef then
		return Result.err(`no item is selected`)
	end
	if tag == "IsItemAdded" then
		return if isSelected then addItem(state, itemDef.Id) else ItemUtil.remove(state, itemDef.Id)
	elseif tag == "HasLenses" or tag == "HasNoLenses" then
		return ItemUtil.setLenses(state, itemDef, (tag == "HasLenses") == isSelected)
	end
	return ItemUtil.setDetailFocus(state, itemDef, tag == "IsLensFocused", isSelected)
end

function Util.read(state: EditorState, field: FieldDefinition): FieldValue
	local out: FieldValue
	if field.Type == "Text" or field.Type == "GenerateAlias" then
		out = { Type = "Text", Text = ProfileUtil.getText(state, field.Binding.Key) }
	elseif field.Type == "SectionHeader" then
		local text = field.Text
		local defaultWord = NUMBER_WORDS[PowerDefinition.DEFAULT_LIMIT]
		if field.Binding and defaultWord then
			-- the text is written for the limit a player starts out with, the number in it follows the limit they have
			local limit = state.Entitlements.PowerLimit
			text = string.gsub(text, defaultWord, NUMBER_WORDS[limit] or tostring(limit), 1)
		end
		out = { Type = "Text", Text = text }
	elseif field.Type == "Choose" then
		local binding = field.Binding
		out = {
			Type = "Choice",
			Value = if binding.Type == "Alignment"
				then ProfileUtil.getAlignment(state, binding.Axis)
				else getTransitionStyle(StateUtil.getIdentity(state).Appearance, binding.TransitionType),
		}
	elseif field.Type == "ChoiceList" then
		out = {
			Type = "Powers",
			Powers = PowerUtil.list(state, field.Binding.Group),
			Count = #state.Character.Powers,
			Limit = state.Entitlements.PowerLimit,
		}
	elseif field.Type == "Color" then
		local binding = field.Binding
		if binding.Type == "SkinColor" then
			out = { Type = "Color", Color = StateUtil.getIdentity(state).Appearance.SkinColor }
		else
			local group = getItemTexture(state, binding)
			out = { Type = "Color", Color = if group then group.Color else nil }
		end
	elseif field.Type == "Material" then
		local group = getItemTexture(state, field.Binding)
		out = { Type = "Material", Material = if group then group.Material else nil }
	else
		out = { Type = "Toggle", IsSelected = Util.getTags(state)[field.Focus] == true }
	end
	TableUtil.deepFreeze(out)
	return out
end

function Util.write(state: EditorState, field: FieldDefinition, edit: FieldEdit): Result<EditorState, string>
	-- a field that's hidden isn't offered, the alias generator isn't the secret identity's to use
	if Util.getIfExcluded(state, field.ExclusionTags) then
		return Result.err(`that can't be changed right now`)
	end
	if field.Type == "Text" and edit.Type == "Text" then
		return ProfileUtil.setText(state, field.Binding.Key, edit.Text, field.MaxLength, field.IsMultiLine == true)
	elseif field.Type == "GenerateAlias" and edit.Type == "Alias" then
		return ProfileUtil.setText(state, field.Binding.Key, AliasDefinition.get(edit.Seed), nil, false)
	elseif field.Type == "Choose" and edit.Type == "Choice" then
		local isChoice = false
		for _, choice in field.Choices do
			isChoice = isChoice or choice.Value == edit.Value
		end
		if not isChoice then
			return Result.err(`"{tostring(edit.Value)}" isn't one of the choices`)
		end
		local binding = field.Binding
		if binding.Type == "Alignment" then
			return ProfileUtil.setAlignment(state, binding.Axis, edit.Value)
		end
		return setTransitionStyle(state, binding.TransitionType, edit.Value)
	elseif field.Type == "ChoiceList" and edit.Type == "Power" then
		return PowerUtil.setSelected(state, field.Binding.Group, edit.Id, edit.IsSelected)
	elseif field.Type == "ChoiceList" and edit.Type == "PowerColor" then
		return PowerUtil.setColor(state, field.Binding.Group, edit.Id, edit.Color)
	elseif field.Type == "Color" and edit.Type == "Color" then
		local color = edit.Color
		if getIfFiltered(field.Filtered, color) then
			return Result.err(`that color isn't offered here`)
		end
		local binding = field.Binding
		if binding.Type == "SkinColor" then
			return setSkinColor(state, color)
		end
		return setItemTexture(state, binding, function(group: TextureGroup): TextureGroup
			return TextureGroupConstructor.new(color, group.Material, group.Transparency)
		end)
	elseif field.Type == "Material" and edit.Type == "Material" then
		local material = edit.Material
		if getIfFiltered(field.Filtered, material) then
			return Result.err(`that material isn't offered here`)
		end
		return setItemTexture(state, field.Binding, function(group: TextureGroup): TextureGroup
			return TextureGroupConstructor.new(group.Color, material, group.Transparency)
		end)
	elseif field.Type == "Toggle" and edit.Type == "Toggle" then
		return Util.setTag(state, field.Focus, edit.IsSelected)
	end
	return Result.err(`a "{field.Type}" field can't take a "{edit.Type}" edit`)
end

Util.getPreviewCharacter = getPreviewCharacter

function Util.getIfChanged(state: EditorState): boolean
	return state.Character ~= state.SavedCharacter and not StateUtil.getIfEqual(state.Character, state.SavedCharacter)
end

return Util
