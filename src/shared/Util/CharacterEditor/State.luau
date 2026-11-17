--!strict
-- Services
-- Packages
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
export type EditorState = CharacterEditorType.EditorState
type Character = CharacterType.Character
type Identity = IdentityType.Identity
type Appearance = AppearanceType.Appearance
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

-- untouched tables keep their identity so the scene doesn't re-dress the rig
function Util.delta(state: EditorState, fn: (t: EditorState) -> ()): EditorState
	local out = table.clone(state)
	fn(out)
	table.freeze(out)
	return out
end

function Util.getIdentity(state: EditorState): Identity
	return state.Character.Identities[state.IdentityKey] or state.Character.Identities.Main
end

function Util.setIdentity(character: Character, identityKey: string, identity: Identity): Character
	local identities = table.clone(character.Identities)
	identities[identityKey] = identity
	table.freeze(identities)
	local out = table.clone(character)
	out.Identities = identities
	table.freeze(out)
	return out
end

function Util.setAppearance(identity: Identity, appearance: Appearance): Identity
	local out = table.clone(identity)
	out.Appearance = appearance
	table.freeze(out)
	return out
end

function Util.setCharacter(state: EditorState, character: Character): EditorState
	if character == state.Character then
		return state
	end
	return Util.delta(state, function(t: EditorState)
		t.Character = character
	end)
end

function Util.setFocusedIdentity(state: EditorState, identity: Identity): EditorState
	return Util.setCharacter(state, Util.setIdentity(state.Character, state.IdentityKey, identity))
end

function Util.setFocusedAppearance(state: EditorState, appearance: Appearance): EditorState
	return Util.setFocusedIdentity(state, Util.setAppearance(Util.getIdentity(state), appearance))
end

-- alignment, transitions + power colors are shared, the edits of those go to every identity
function Util.editIdentities(state: EditorState, fn: (identity: Identity) -> Identity): EditorState
	local character = state.Character
	for identityKey, identity in state.Character.Identities do
		if not identity then
			continue
		end
		local editedIdentity = fn(identity)
		if editedIdentity ~= identity then
			character = Util.setIdentity(character, identityKey, editedIdentity)
		end
	end
	return Util.setCharacter(state, character)
end

function Util.getIfEqual(a: unknown, b: unknown): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	local tableA, tableB = a :: { [unknown]: unknown }, b :: { [unknown]: unknown }
	for key, value in tableA do
		if not Util.getIfEqual(value, tableB[key]) then
			return false
		end
	end
	for key in tableB do
		if tableA[key] == nil then
			return false
		end
	end
	return true
end

return Util
