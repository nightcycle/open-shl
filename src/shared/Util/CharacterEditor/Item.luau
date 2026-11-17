--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local PageUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Page")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type EditorState = CharacterEditorType.EditorState
type ItemTextureBinding = CharacterEditorType.ItemTextureBinding
type IdentityKey = CharacterType.IdentityKey
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
local DETAIL_TEXTURE_GROUP_KEY: TextureGroupKey = CharacterEditorDefinition.DETAIL_TEXTURE_GROUP_KEY :: TextureGroupKey
-- the detail group of a mask is its lenses, on anything else it's the edges
local LENS_ITEM_TAG: AppearanceType.ItemDefinitionTag = "Mask"
local IDENTITY_NAMES: { [IdentityKey]: string } = table.freeze({
	Main = "super",
	Secret = "secret",
})
-- Variables
-- References
-- Private Functions
local function getIfSameTextureGroup(a: TextureGroup, b: TextureGroup): boolean
	return a.Color == b.Color and a.Material == b.Material and a.Transparency == b.Transparency
end

-- the worn item when it's worn, the one that's tried on otherwise
local function edit(state: EditorState, definitionId: string, fn: (item: Item) -> ()): EditorState
	local appearance = StateUtil.getIdentity(state).Appearance
	for _, wornItem in appearance.Items do
		if wornItem.DefinitionId == definitionId then
			return StateUtil.setFocusedAppearance(
				state,
				FreezeUtil.delta(appearance, function(t: Appearance): Appearance
					for _, item in t.Items do
						if item.DefinitionId == definitionId then
							fn(item)
						end
					end
					return t
				end)
			)
		end
	end
	local pendingItem = state.PendingItem
	local triedItem: Item = if pendingItem and pendingItem.DefinitionId == definitionId
		then pendingItem
		else ItemConstructor.new(definitionId)
	local editedItem = FreezeUtil.delta(triedItem, function(t: Item): Item
		fn(t)
		return t
	end)
	return StateUtil.delta(state, function(t: EditorState)
		t.PendingItem = editedItem
	end)
end

local function getIfStacking(state: EditorState, definitionId: string): boolean
	local pathOpt = CharacterEditorDefinition.getItemPath(definitionId)
	local page = if pathOpt.IsSome then PageUtil.get(pathOpt.Value) else nil
	if not page or page.Type ~= "Item" then
		return false
	end
	return page.WearRule == "Multi" or (page.WearRule == "MultiHair" and state.Entitlements.HasMultiHair)
end

-- Class
local Util = {}

function Util.getName(definitionId: string): string
	local itemDefRes = ItemAppearanceDefinition.get(definitionId)
	return if itemDefRes.IsOk and itemDefRes.Value.Name then itemDefRes.Value.Name else definitionId
end

function Util.getPath(state: EditorState, definitionId: string): Result<string, string>
	local pathOpt = CharacterEditorDefinition.getItemPath(definitionId)
	if pathOpt.IsNone then
		return Result.err(`"{Util.getName(definitionId)}" isn't worn through the editor`)
	end
	-- a costume is for the super identity + clothing for the secret one, the pages say which is which
	if PageUtil.getIfClosed(state.IdentityKey, pathOpt.Value) then
		return Result.err(`the {IDENTITY_NAMES[state.IdentityKey]} identity can't wear "{Util.getName(definitionId)}"`)
	end
	return Result.ok(pathOpt.Value)
end

function Util.find(appearance: Appearance, definitionId: string): Item?
	for _, item in appearance.Items do
		if item.DefinitionId == definitionId then
			return item
		end
	end
	return nil
end

function Util.getTarget(state: EditorState, definitionId: string): Item?
	local wornItem = Util.find(StateUtil.getIdentity(state).Appearance, definitionId)
	if wornItem then
		return wornItem
	end
	local pendingItem = state.PendingItem
	return if pendingItem and pendingItem.DefinitionId == definitionId then pendingItem else nil
end

-- a group that was never edited looks like the template
function Util.getTextureGroup(
	state: EditorState,
	definitionId: string,
	key: TextureGroupKey
): Result<TextureGroup, string>
	local targetItem = Util.getTarget(state, definitionId)
	local group = if targetItem then targetItem.TextureGroups[key] else nil
	if group then
		return Result.ok(group)
	end
	return ItemAppearanceDefinition.getDefaultTextureGroup(definitionId, key)
end

function Util.getTextureGroupKey(
	state: EditorState,
	itemDef: ItemDefinition,
	binding: ItemTextureBinding
): TextureGroupKey?
	local key: TextureGroupKey? = binding.Group or state.FocusedGroup
	if not key then
		local mainKeyOpt = CharacterEditorDefinition.getMainTextureGroup(itemDef)
		key = if mainKeyOpt.IsSome then mainKeyOpt.Value else nil
	end
	if not key or table.find(itemDef.TextureGroups, key) == nil then
		return nil
	end
	return key
end

-- an edit stores the whole group, what it didn't touch is filled in from the template
function Util.setTextureGroup(
	state: EditorState,
	itemDef: ItemDefinition,
	key: TextureGroupKey,
	fn: (group: TextureGroup) -> TextureGroup
): Result<EditorState, string>
	local groupRes = Util.getTextureGroup(state, itemDef.Id, key)
	if groupRes.IsErr then
		return Result.err(`"{Util.getName(itemDef.Id)}" can't be changed there`)
	end
	local group = fn(groupRes.Value)
	-- pressing what's already picked changes nothing, unless there's no item yet to show it on
	if Util.getTarget(state, itemDef.Id) and getIfSameTextureGroup(group, groupRes.Value) then
		return Result.ok(state)
	end
	return Result.ok(edit(state, itemDef.Id, function(item: Item)
		item.TextureGroups[key] = group
	end))
end

function Util.getIfLensItem(itemDef: ItemDefinition): boolean
	return table.find(itemDef.TextureGroups, DETAIL_TEXTURE_GROUP_KEY) ~= nil
		and table.find(itemDef.Tags, LENS_ITEM_TAG) ~= nil
end

-- lenses are part of the mask, taking them off only turns them see-through
function Util.getIfLensesShown(state: EditorState, itemDef: ItemDefinition): boolean
	if not Util.getIfLensItem(itemDef) then
		return false
	end
	local groupRes = Util.getTextureGroup(state, itemDef.Id, DETAIL_TEXTURE_GROUP_KEY)
	return groupRes.IsOk and groupRes.Value.Transparency < 1
end

function Util.setLenses(state: EditorState, itemDef: ItemDefinition, isShown: boolean): Result<EditorState, string>
	if not Util.getIfLensItem(itemDef) then
		return Result.err(`"{Util.getName(itemDef.Id)}" has no lenses`)
	end
	local stateRes = Util.setTextureGroup(
		state,
		itemDef,
		DETAIL_TEXTURE_GROUP_KEY,
		function(group: TextureGroup): TextureGroup
			return TextureGroupConstructor.new(group.Color, group.Material, if isShown then 0 else 1)
		end
	)
	if stateRes.IsErr or isShown or stateRes.Value.FocusedGroup == nil then
		return stateRes
	end
	-- the palettes go back to the mask itself
	return Result.ok(StateUtil.delta(stateRes.Value, function(t: EditorState)
		t.FocusedGroup = nil
	end))
end

function Util.setDetailFocus(
	state: EditorState,
	itemDef: ItemDefinition,
	isLensFocus: boolean,
	isFocused: boolean
): Result<EditorState, string>
	local hasDetail = table.find(itemDef.TextureGroups, DETAIL_TEXTURE_GROUP_KEY) ~= nil
	if not hasDetail or Util.getIfLensItem(itemDef) ~= isLensFocus then
		return Result.err(`"{Util.getName(itemDef.Id)}" has no {if isLensFocus then "lenses" else "edges"}`)
	end
	if isFocused and isLensFocus and not Util.getIfLensesShown(state, itemDef) then
		return Result.err(`"{Util.getName(itemDef.Id)}" has its lenses off`)
	end
	local focusedGroup: TextureGroupKey? = if isFocused then DETAIL_TEXTURE_GROUP_KEY else nil
	if state.FocusedGroup == focusedGroup then
		return Result.ok(state)
	end
	return Result.ok(StateUtil.delta(state, function(t: EditorState)
		t.FocusedGroup = focusedGroup
	end))
end

-- the rest of its category comes off, unless the category stacks
function Util.removeReplaced(state: EditorState, items: { Item }, definitionId: string)
	if getIfStacking(state, definitionId) then
		return
	end
	local indexRes = ItemAppearanceDefinition.getIndex(definitionId)
	if indexRes.IsErr then
		return
	end
	for i = #items, 1, -1 do
		local wornIndexRes = ItemAppearanceDefinition.getIndex(items[i].DefinitionId)
		if
			wornIndexRes.IsOk
			and wornIndexRes.Value.Group == indexRes.Value.Group
			and wornIndexRes.Value.Category == indexRes.Value.Category
		then
			table.remove(items, i)
		end
	end
end

-- carries the picked look over to the next item of the category
function Util.newPending(state: EditorState, definitionId: string): Item
	local previousItem = state.PendingItem
	if not previousItem then
		return ItemConstructor.new(definitionId)
	end
	if previousItem.DefinitionId == definitionId then
		return previousItem
	end
	local itemDefRes = ItemAppearanceDefinition.get(definitionId)
	local indexRes = ItemAppearanceDefinition.getIndex(definitionId)
	local previousIndexRes = ItemAppearanceDefinition.getIndex(previousItem.DefinitionId)
	if
		itemDefRes.IsErr
		or indexRes.IsErr
		or previousIndexRes.IsErr
		or indexRes.Value.Group ~= previousIndexRes.Value.Group
		or indexRes.Value.Category ~= previousIndexRes.Value.Category
	then
		return ItemConstructor.new(definitionId)
	end
	return FreezeUtil.delta(ItemConstructor.new(definitionId), function(t: Item): Item
		for _, key: TextureGroupKey in itemDefRes.Value.TextureGroups do
			local previousGroup = previousItem.TextureGroups[key]
			if not previousGroup then
				continue
			end
			local previousDefaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(previousItem.DefinitionId, key)
			local defaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(definitionId, key)
			if previousDefaultRes.IsErr or defaultRes.IsErr then
				continue
			end
			local previousDefault, default = previousDefaultRes.Value, defaultRes.Value
			local group = TextureGroupConstructor.new(
				if previousGroup.Color == previousDefault.Color then default.Color else previousGroup.Color,
				if previousGroup.Material == previousDefault.Material then default.Material else previousGroup.Material,
				if previousGroup.Transparency == previousDefault.Transparency
					then default.Transparency
					else previousGroup.Transparency
			)
			if not getIfSameTextureGroup(group, default) then
				t.TextureGroups[key] = group
			end
		end
		return t
	end)
end

function Util.add(state: EditorState, definitionId: string): Result<EditorState, string>
	local pathRes = Util.getPath(state, definitionId)
	if pathRes.IsErr then
		return pathRes
	end
	local appearance = StateUtil.getIdentity(state).Appearance
	if Util.find(appearance, definitionId) then
		return Result.ok(state)
	end
	local pendingItem = state.PendingItem
	local isPending = pendingItem ~= nil and pendingItem.DefinitionId == definitionId
	local item = if pendingItem and isPending then pendingItem else ItemConstructor.new(definitionId)
	local wornState = StateUtil.setFocusedAppearance(
		state,
		FreezeUtil.delta(appearance, function(t: Appearance): Appearance
			Util.removeReplaced(state, t.Items, definitionId)
			table.insert(t.Items, item)
			return t
		end)
	)
	if not isPending then
		return Result.ok(wornState)
	end
	return Result.ok(StateUtil.delta(wornState, function(t: EditorState)
		t.PendingItem = nil
	end))
end

function Util.remove(state: EditorState, definitionId: string): Result<EditorState, string>
	local appearance = StateUtil.getIdentity(state).Appearance
	if not Util.find(appearance, definitionId) then
		return Result.ok(state)
	end
	local removedState = StateUtil.setFocusedAppearance(
		state,
		FreezeUtil.delta(appearance, function(t: Appearance): Appearance
			for i = #t.Items, 1, -1 do
				if t.Items[i].DefinitionId == definitionId then
					table.remove(t.Items, i)
				end
			end
			return t
		end)
	)
	local page = PageUtil.get(state.Path)
	local isOpen = page ~= nil and page.Type == "Item" and page.DefinitionId == definitionId
	if not isOpen or state.FocusedGroup == nil then
		return Result.ok(removedState)
	end
	-- the palettes have nothing left to point at
	return Result.ok(StateUtil.delta(removedState, function(t: EditorState)
		t.FocusedGroup = nil
	end))
end

return Util
