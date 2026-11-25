--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Appearance = AppearanceType.Appearance
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
type Item = AppearanceType.Item
type ItemGroup = AppearanceType.ItemGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
-- what a roll never deals + so never takes away: whatever the draft wore of it stays on
local KEPT_GROUP: ItemGroup = "costume"
local KEPT_CATEGORY = "accessories"
local IDENTITY_KEYS: { IdentityKey } = table.freeze({ "Main" :: IdentityKey, "Secret" })
-- Variables
-- References
-- Private Functions
-- the shelf an item is off, nil for one the game doesn't have
local function getShelf(item: Item): string?
	local indexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
	return if indexRes.IsOk then `{indexRes.Value.Group}/{indexRes.Value.Category}` else nil
end

-- what the roll dealt an identity, in the patterns + materials of what the draft wore of the same kind, with the
-- draft's accessories + its size
local function mergeAppearance(draft: Appearance, roll: Appearance): Appearance
	return FreezeUtil.delta(roll, function(t: Appearance): Appearance
		t.Scale = draft.Scale
		for _, item in t.Items do
			local shelf = getShelf(item)
			for _, draftItem in draft.Items do
				if not shelf or getShelf(draftItem) ~= shelf then
					continue
				end
				for key: TextureGroupKey, textureGroup in item.TextureGroups do
					local draftGroup = draftItem.TextureGroups[key]
					if textureGroup and draftGroup then
						textureGroup.Pattern = draftGroup.Pattern
						textureGroup.Material = draftGroup.Material
					end
				end
				break
			end
		end
		for _, draftItem in draft.Items do
			if getShelf(draftItem) == `{KEPT_GROUP}/{KEPT_CATEGORY}` then
				table.insert(t.Items, draftItem)
			end
		end
		return t
	end)
end
-- Class
local Util = {}

-- what a draft becomes when its player asks for somebody else: the roll, as the same body in the same slot. the old
-- game's button never touched the size, the patterns, the materials or the accessories of the character it rolled
-- into, + wrote over everything else, both names + the backstory with it
function Util.merge(draft: Character, roll: Character): Character
	return FreezeUtil.delta(roll, function(t: Character): Character
		t.Id = draft.Id
		for _, identityKey: IdentityKey in IDENTITY_KEYS do
			local identity, draftIdentity = t.Identities[identityKey], draft.Identities[identityKey]
			if identity and draftIdentity then
				identity.Appearance = mergeAppearance(draftIdentity.Appearance, identity.Appearance)
			end
		end
		return t
	end)
end

return Util
