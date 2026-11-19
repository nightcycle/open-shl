--!strict
-- Services
-- Packages
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type FieldDefinition = CharacterEditorType.FieldDefinition
type PageDefinition = CharacterEditorType.PageDefinition
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
type Identity = IdentityType.Identity
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
-- Constants
-- Variables
-- the items every identity wears the same, by the id of their definition
local IsItemShared: { [string]: true } = {}
local IsBackstoryShared = false
-- the game has a switch that ties the skin of the identities together
local IsColorLinked = false
-- the game has the skin picked on a page every identity shares: there's one skin to a character
local IsSkinShared = false
-- References
-- Private Functions
local function indexFields(fields: { FieldDefinition }, isShared: boolean)
	for _, field in fields do
		if field.Type == "Text" then
			IsBackstoryShared = IsBackstoryShared or (isShared and field.Binding.Key == "Backstory")
		elseif field.Type == "Color" then
			IsSkinShared = IsSkinShared or (isShared and field.Binding.Type == "SkinColor")
		elseif field.Type == "Toggle" then
			IsColorLinked = IsColorLinked or field.Focus == "IsColorMatched"
			indexFields(field.Sections or {}, isShared)
			indexFields(field.DisabledSections or {}, isShared)
		end
	end
end

local function indexPage(page: PageDefinition)
	-- nothing is edited on a step, so there's nothing of it to share
	if page.Type == "Step" then
		return
	end
	local isShared = page.IsShared == true
	if page.Type == "Item" then
		if isShared then
			IsItemShared[page.DefinitionId] = true
		end
	elseif page.Type == "Set" then
		-- what a set wears is shared the way an item of its own page is
		if isShared then
			for _, definitionId in page.DefinitionIds do
				IsItemShared[definitionId] = true
			end
		end
	elseif page.Children then
		for _, child in page.Children do
			indexPage(child)
		end
	end
	if page.Fields then
		indexFields(page.Fields, isShared)
	end
end

-- what's worn of the shared items is what the source wears of them, the rest stays where it was. the very list
-- comes back when there's nothing to take over, so a scene doesn't dress its rig again
local function getItems(sourceItems: { Item }, items: { Item }): { Item }
	local sourceItemsById: { [string]: Item } = {}
	for _, item in sourceItems do
		if IsItemShared[item.DefinitionId] then
			sourceItemsById[item.DefinitionId] = item
		end
	end
	local out: { Item } = {}
	local isKept: { [string]: true } = {}
	local isChanged = false
	for _, item in items do
		if not IsItemShared[item.DefinitionId] then
			table.insert(out, item)
			continue
		end
		local sourceItem = sourceItemsById[item.DefinitionId]
		if not sourceItem then
			isChanged = true
			continue
		end
		isKept[item.DefinitionId] = true
		if sourceItem == item or StateUtil.getIfEqual(sourceItem, item) then
			table.insert(out, item)
		else
			table.insert(out, sourceItem)
			isChanged = true
		end
	end
	for _, item in sourceItems do
		if IsItemShared[item.DefinitionId] and not isKept[item.DefinitionId] then
			table.insert(out, item)
			isChanged = true
		end
	end
	if not isChanged then
		return items
	end
	table.freeze(out)
	return out
end

local function share(source: Identity, identity: Identity): Identity
	local appearance = identity.Appearance
	local items = getItems(source.Appearance.Items, appearance.Items)
	local skinColor = if IsColorLinked or IsSkinShared then source.Appearance.SkinColor else appearance.SkinColor
	if items ~= appearance.Items or skinColor ~= appearance.SkinColor then
		local editedAppearance: Appearance = table.clone(appearance)
		editedAppearance.Items = items
		editedAppearance.SkinColor = skinColor
		table.freeze(editedAppearance)
		appearance = editedAppearance
	end
	local profile = identity.Profile
	if IsBackstoryShared and profile.Backstory ~= source.Profile.Backstory then
		local editedProfile = table.clone(profile)
		editedProfile.Backstory = source.Profile.Backstory
		table.freeze(editedProfile)
		profile = editedProfile
	end
	if appearance == identity.Appearance and profile == identity.Profile then
		return identity
	end
	local out = table.clone(identity)
	out.Appearance = appearance
	out.Profile = profile
	table.freeze(out)
	return out
end
-- Class
-- a character is one person: its hair, its face + what's told of it are the same whoever it's out as. which of it
-- that is are the pages the game's editor marks as shared, a game that marks none has identities that share nothing
local Util = {}

indexPage(CharacterEditorDefinition.DEFINITION)

-- nothing here does anything in a game where this is false
Util.IS_ANY = next(IsItemShared) ~= nil or IsBackstoryShared or IsColorLinked or IsSkinShared

-- until the switch can take them apart, the skin + the hair of the identities are tied together
Util.IS_COLOR_LINKED = IsColorLinked

-- the character with what's shared of that identity taken over by every other one of its identities
function Util.apply(character: Character, sourceKey: IdentityKey): Character
	local source = character.Identities[sourceKey]
	if not Util.IS_ANY or not source then
		return character
	end
	local out = character
	for identityKey, identity in character.Identities do
		if identityKey == sourceKey or not identity then
			continue
		end
		local sharedIdentity = share(source, identity)
		if sharedIdentity ~= identity then
			out = StateUtil.setIdentity(out, identityKey, sharedIdentity)
		end
	end
	return out
end

return Util
