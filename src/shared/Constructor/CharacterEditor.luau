--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local IdentityConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type EditorState = CharacterEditorType.EditorState
export type Entitlements = CharacterEditorType.Entitlements
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
-- Constants
local IDENTITY_KEYS: { IdentityKey } = table.freeze({ "Main" :: IdentityKey, "Secret" })
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.newEntitlements = function(powerLimit: number?, hasMultiHair: boolean?): Entitlements
	local out: Entitlements = {
		PowerLimit = powerLimit or PowerDefinition.DEFAULT_LIMIT,
		HasMultiHair = hasMultiHair == true,
	}
	table.freeze(out)
	return out
end

Module.new = function(character: Character, entitlements: Entitlements?, identityKey: IdentityKey?): EditorState
	-- a state is frozen all the way down
	if not table.isfrozen(character) then
		character = FreezeUtil.delta(character, function(t: Character): Character
			return t
		end)
	end
	local draft = character
	-- a character that lost an identity gets a blank one to edit
	for _, key in IDENTITY_KEYS do
		if draft.Identities[key] == nil then
			local identities = table.clone(draft.Identities)
			identities[key] = IdentityConstructor.new()
			table.freeze(identities)
			draft = table.clone(draft)
			draft.Identities = identities
			table.freeze(draft)
		end
	end
	local out: EditorState = {
		Character = draft,
		SavedCharacter = draft,
		IdentityKey = identityKey or "Main",
		Path = "",
		Entitlements = entitlements or Module.newEntitlements(),
	}
	table.freeze(out)
	return out
end

return Module
