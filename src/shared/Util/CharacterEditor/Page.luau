--!strict
-- Services
-- Packages
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type EditorState = CharacterEditorType.EditorState
export type PageDefinition = CharacterEditorType.PageDefinition
export type Tag = CharacterEditorType.Tag
export type Tags = { [Tag]: true? }
type IdentityKey = CharacterType.IdentityKey
type ItemDefinition = AppearanceType.ItemDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.get(path: string): PageDefinition?
	local pageOpt = CharacterEditorDefinition.getPage(path)
	return if pageOpt.IsSome then pageOpt.Value else nil
end

function Util.getItemDefinition(state: EditorState): ItemDefinition?
	local page = Util.get(state.Path)
	if not page or page.Type ~= "Item" then
		return nil
	end
	local itemDefRes = ItemAppearanceDefinition.get(page.DefinitionId)
	return if itemDefRes.IsOk then itemDefRes.Value else nil
end

function Util.getIdentityTag(identityKey: IdentityKey): Tag
	return if identityKey == "Main" then "IsSuper" else "IsSecret"
end

function Util.getIfExcluded(tags: Tags, exclusionTags: { Tag }?): boolean
	if exclusionTags then
		for _, tag: Tag in exclusionTags do
			if tags[tag] then
				return true
			end
		end
	end
	return false
end

-- pages are only ever hidden from an identity, a path is closed to it when a page along the way is
function Util.getIfClosed(identityKey: IdentityKey, path: string): boolean
	local identityTag = Util.getIdentityTag(identityKey)
	local currentPath: string? = path
	while currentPath and currentPath ~= "" do
		local page = Util.get(currentPath)
		if not page or (page.ExclusionTags and table.find(page.ExclusionTags, identityTag)) then
			return true
		end
		local parentPathOpt = CharacterEditorDefinition.getParentPath(currentPath)
		currentPath = if parentPathOpt.IsSome then parentPathOpt.Value else nil
	end
	return false
end

return Util
