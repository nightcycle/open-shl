--!strict
-- Services
-- Packages
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Types")
type Character = CharacterType.Character
type EditorState = CharacterEditorType.EditorState
type FieldDefinition = CharacterEditorType.FieldDefinition
type PageInfo = Types.PageInfo
type RowInfo = Types.RowInfo
export type Listing = AccessDefinition.Listing
export type Owned = AccessDefinition.Owned
-- what a draft is short of + what that's worked out from: what its player has, what the slot holds as it's stored
export type Hold = {
	Owned: Owned,
	Kept: AccessDefinition.Kept,
	Needed: { Listing },
}
-- Constants
local NO_FIELDS: { FieldDefinition } = table.freeze({})
-- Variables
-- References
-- Private Functions
-- Class
-- what the rows of a page ask about what the game holds back. it's the question the server asks of the draft once
-- it's handed in, asked ahead of it: a page that'd be turned down isn't left
local Module = {}

-- what the draft wears + wields that isn't its player's. whatever the slot holds as it's stored may stay where it is
Module.new = function(draft: Character, stored: Character, owned: Owned): Hold
	local kept = AccessDefinition.getKept(stored)
	return table.freeze({
		Owned = owned,
		Kept = kept,
		Needed = AccessDefinition.getUnowned(draft, owned, kept),
	})
end

-- the field of a kind a row is about, by its place among the fields of that kind on the page
Module.findField = function(pageKey: string, fieldType: string, index: number): FieldDefinition?
	local pageOpt = CharacterEditorDefinition.getPage(pageKey)
	if pageOpt.IsNone or pageOpt.Value.Type ~= "Default" then
		return nil
	end
	local count = 0
	local fields: { FieldDefinition } = pageOpt.Value.Fields or NO_FIELDS
	for _, field in fields do
		if field.Type == fieldType then
			count += 1
			if count == index then
				return field
			end
		end
	end
	return nil
end

-- what a row has on, by its ids: what the identity in focus wears of the row's list, the power that's picked of its
-- field. a row that steps through neither has nothing on
Module.listHeldIds = function(state: EditorState, pageKey: string, row: RowInfo): { string }
	local out: { string } = {}
	local source = row.Source
	if source.Type == "Items" or source.Type == "Sets" or source.Type == "Extras" then
		local folderOpt = CharacterEditorDefinition.getPage(source.Folder)
		if folderOpt.IsNone or folderOpt.Value.Type ~= "Default" or not folderOpt.Value.Children then
			return out
		end
		for _, child in folderOpt.Value.Children do
			local definitionIds: { string } = if child.Type == "Item"
				then { child.DefinitionId }
				elseif child.Type == "Set" then child.DefinitionIds
				else {}
			for _, definitionId in definitionIds do
				if CharacterEditorUtil.getIfItemWorn(state, definitionId) then
					table.insert(out, definitionId)
				end
			end
		end
	elseif source.Type == "Power" then
		local field = Module.findField(pageKey, "ChoiceList", source.Field)
		if field and field.Type == "ChoiceList" then
			local value = CharacterEditorUtil.read(state, field)
			for _, choice in field.Choices do
				if value.Type == "Powers" and value.Powers[choice.Value] then
					table.insert(out, choice.Value)
				end
			end
		end
	end
	return out
end

-- what a row is held by: the first thing it has on that the draft is short of, by its id + its listing. nothing for
-- a row whose arrows pass over what's held back, that's only ever on through the row it hangs under
Module.getHeld = function(hold: Hold, state: EditorState, pageKey: string, row: RowInfo): (string?, Listing?)
	local source = row.Source
	if #hold.Needed == 0 or (source.Type == "Items" and source.IsPassingLocked) then
		return nil, nil
	end
	for _, id in Module.listHeldIds(state, pageKey, row) do
		local listing = AccessDefinition.getOf(id)
		if listing and table.find(hold.Needed, listing) then
			return id, listing
		end
	end
	return nil, nil
end

-- whether a row of the page is held, the rows that hang under one among them: the page isn't left ahead meanwhile
Module.getIfPageHeld = function(hold: Hold, state: EditorState, page: PageInfo): boolean
	local function getIfAnyHeld(rows: { RowInfo }?): boolean
		if rows then
			for _, row in rows do
				if Module.getHeld(hold, state, page.Key, row) ~= nil or getIfAnyHeld(row.Rows) then
					return true
				end
			end
		end
		return false
	end
	return getIfAnyHeld(page.Rows)
end

-- whether an item is one the draft would be short of on the identity in focus: neither its player's nor the slot's
Module.getIfShort = function(hold: Hold, state: EditorState, itemId: string): boolean
	local keptIds = hold.Kept.ItemIds[state.IdentityKey]
	return not (keptIds and keptIds[itemId]) and not AccessDefinition.getIfOwned(hold.Owned, itemId)
end

return Module
