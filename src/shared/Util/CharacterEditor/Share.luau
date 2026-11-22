--!strict
-- Services
-- Packages
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
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
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
-- the group a head of hair is colored by
local HAIR_TEXTURE_GROUP_KEY: TextureGroupKey = "Hair"
-- Variables
-- the items every identity wears the same, by the id of their definition
local IsItemShared: { [string]: true } = {}
-- the ones of them that are a head of hair with a color to pick: the switch of the game has that color follow it
local IsHairColored: { [string]: true } = {}
-- the ones that are hair nobody picks a color for, a beard: they take the color of the head of hair they're worn with
local IsHairTinted: { [string]: true } = {}
local IsBackstoryShared = false
-- the game has a switch that ties the skin + the hair color of the identities together
local IsColorLinked = false
-- the game has the skin picked on a page every identity shares: there's one skin to a character
local IsSkinShared = false
-- References
-- Private Functions
local function indexFields(fields: { FieldDefinition }, isShared: boolean, definitionId: string?)
	for _, field in fields do
		if field.Type == "Text" then
			IsBackstoryShared = IsBackstoryShared or (isShared and field.Binding.Key == "Backstory")
		elseif field.Type == "Color" then
			local binding = field.Binding
			IsSkinShared = IsSkinShared or (isShared and binding.Type == "SkinColor")
			if
				isShared
				and definitionId
				and binding.Type == "ItemTexture"
				and binding.Group == HAIR_TEXTURE_GROUP_KEY
			then
				IsHairColored[definitionId] = true
			end
		elseif field.Type == "Toggle" then
			IsColorLinked = IsColorLinked or field.Focus == "IsColorMatched"
			indexFields(field.Sections or {}, isShared, definitionId)
			indexFields(field.DisabledSections or {}, isShared, definitionId)
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
		indexFields(page.Fields, isShared, if page.Type == "Item" then page.DefinitionId else nil)
	end
end

local function findHair(items: { Item }): Item?
	for _, item in items do
		if IsHairColored[item.DefinitionId] then
			return item
		end
	end
	return nil
end

-- a group that was never edited looks like the template
local function getHairColor(hair: Item): Color3?
	local group = hair.TextureGroups[HAIR_TEXTURE_GROUP_KEY]
	if group then
		return group.Color
	end
	local defaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(hair.DefinitionId, HAIR_TEXTURE_GROUP_KEY)
	return if defaultRes.IsOk then defaultRes.Value.Color else nil
end

-- the hair of the source in the color the hair of an identity has
local function dye(sourceHair: Item, hair: Item): Item
	local group: TextureGroup? = hair.TextureGroups[HAIR_TEXTURE_GROUP_KEY]
	local sourceGroup: TextureGroup? = sourceHair.TextureGroups[HAIR_TEXTURE_GROUP_KEY]
	if group == sourceGroup or StateUtil.getIfEqual(group, sourceGroup) then
		return sourceHair
	end
	local textureGroups = table.clone(sourceHair.TextureGroups)
	textureGroups[HAIR_TEXTURE_GROUP_KEY] = group
	table.freeze(textureGroups)
	local out = table.clone(sourceHair)
	out.TextureGroups = textureGroups
	table.freeze(out)
	return out
end

-- what takes the color of a head of hair in the color of the one among those items: a beard that's put on comes as
-- it was made, + the hair it's worn with may be colored after it. the very list comes back when all of it is already
local function tint(items: { Item }): { Item }
	local hair = if next(IsHairTinted) ~= nil then findHair(items) else nil
	if not hair then
		return items
	end
	local out: { Item }? = nil
	for index, item in items do
		local tintedItem = if IsHairTinted[item.DefinitionId] then dye(item, hair) else item
		if tintedItem ~= item then
			local tintedItems: { Item } = out or table.clone(items)
			tintedItems[index] = tintedItem
			out = tintedItems
		end
	end
	if not out then
		return items
	end
	table.freeze(out)
	return out
end

local function tintIdentity(identity: Identity): Identity
	local items = tint(identity.Appearance.Items)
	if items == identity.Appearance.Items then
		return identity
	end
	local appearance: Appearance = table.clone(identity.Appearance)
	appearance.Items = items
	table.freeze(appearance)
	local out = table.clone(identity)
	out.Appearance = appearance
	table.freeze(out)
	return out
end

-- what's worn of the shared items is what the source wears of them, the rest stays where it was. where the switch of
-- a game has the colors apart a head of hair comes in the color of the hair it's worn in the place of, + so does what
-- takes its color. the very list comes back when there's nothing to take over, so a scene doesn't dress its rig again
local function getItems(sourceItems: { Item }, items: { Item }, isColorMatched: boolean): { Item }
	local hair: Item? = if IsColorLinked and not isColorMatched then findHair(items) else nil
	local sourceItemsById: { [string]: Item } = {}
	for _, item in sourceItems do
		if IsItemShared[item.DefinitionId] then
			local isDyed = IsHairColored[item.DefinitionId] or IsHairTinted[item.DefinitionId]
			sourceItemsById[item.DefinitionId] = if hair and isDyed then dye(item, hair) else item
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
			table.insert(out, sourceItemsById[item.DefinitionId])
			isChanged = true
		end
	end
	if not isChanged then
		return items
	end
	table.freeze(out)
	return out
end

local function share(source: Identity, identity: Identity, isColorMatched: boolean): Identity
	local appearance = identity.Appearance
	local items = getItems(source.Appearance.Items, appearance.Items, isColorMatched)
	local skinColor = if isColorMatched or IsSkinShared then source.Appearance.SkinColor else appearance.SkinColor
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
-- where a head of hair has a color to pick, whatever else is shared + made of hair goes by it
if next(IsHairColored) ~= nil then
	for definitionId in IsItemShared do
		local itemDefRes = ItemAppearanceDefinition.get(definitionId)
		if
			not IsHairColored[definitionId]
			and itemDefRes.IsOk
			and table.find(itemDefRes.Value.TextureGroups, HAIR_TEXTURE_GROUP_KEY) ~= nil
		then
			IsHairTinted[definitionId] = true
		end
	end
end

-- nothing here does anything in a game where this is false
Util.IS_ANY = next(IsItemShared) ~= nil or IsBackstoryShared or IsColorLinked or IsSkinShared

-- the game has a switch that ties the skin + the hair color of the identities together or takes them apart
Util.IS_COLOR_LINKED = IsColorLinked

-- whether the identities have one skin + one hair color between them. for a character nobody is editing that's all
-- there is to say how the switch stands: a save keeps the colors, not the switch
function Util.getIfColorMatched(character: Character): boolean
	if not IsColorLinked then
		return false
	end
	local main = character.Identities.Main
	local mainHair = findHair(main.Appearance.Items)
	local mainHairColor: Color3? = if mainHair then getHairColor(mainHair) else nil
	for _, identity in character.Identities do
		if not identity or identity == main then
			continue
		end
		-- compared as hex: a color that went through a save or a remote may not be bit equal to what it was
		if identity.Appearance.SkinColor:ToHex() ~= main.Appearance.SkinColor:ToHex() then
			return false
		end
		local hair = findHair(identity.Appearance.Items)
		local hairColor: Color3? = if hair then getHairColor(hair) else nil
		-- somebody bald has no hair color to be another one
		if mainHairColor and hairColor and hairColor:ToHex() ~= mainHairColor:ToHex() then
			return false
		end
	end
	return true
end

-- an item that takes the color of a head of hair, in the color of the one among those items. any other item comes
-- back as it is, + so does one that's worn with no hair
function Util.tint(items: { Item }, item: Item): Item
	if not IsHairTinted[item.DefinitionId] then
		return item
	end
	local hair = findHair(items)
	return if hair then dye(item, hair) else item
end

-- the character with what's shared of that identity taken over by every other one of its identities. where the game
-- has the switch the skin + the hair color only go along while it has them matched, each identity keeps its own
-- otherwise. what takes the color of the hair it's worn with is in it on every one of them
function Util.apply(character: Character, sourceKey: IdentityKey, isColorMatched: boolean?): Character
	local untintedSource = character.Identities[sourceKey]
	if not Util.IS_ANY or not untintedSource then
		return character
	end
	local isMatched = IsColorLinked and isColorMatched == true
	local out = character
	local source = tintIdentity(untintedSource)
	if source ~= untintedSource then
		out = StateUtil.setIdentity(out, sourceKey, source)
	end
	for identityKey, identity in character.Identities do
		if identityKey == sourceKey or not identity then
			continue
		end
		local sharedIdentity = share(source, identity, isMatched)
		if sharedIdentity ~= identity then
			out = StateUtil.setIdentity(out, identityKey, sharedIdentity)
		end
	end
	return out
end

return Util
