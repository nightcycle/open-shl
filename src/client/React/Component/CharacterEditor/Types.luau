--!strict
-- Services
-- Packages
-- Modules
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
type ProfileKey = CharacterEditorType.ProfileKey
export type TextFilter = {
	Path: string, -- the page the text is on
	IdentityKey: IdentityKey,
	Key: ProfileKey,
	Text: string,
}
export type FilteredText = {
	Filter: TextFilter,
	Text: string, -- what the text reads like once it's filtered
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
