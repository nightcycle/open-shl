--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
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
export type ActionInfo =
	{
		Type: "Save",
		Character: Character,
	}
	| {
		Type: "FilterText",
		Filter: TextFilter,
	}
	| {
		Type: "Back",
	}
	| {
		Type: "Exit",
	}
	| {
		Type: "Randomize", -- asks for the draft to be rolled all over again
	}
	| {
		Type: "SetPeaceful", -- asks for the player to sit fights out or not, in a game where that's a player's pick
		IsPeaceful: boolean,
	}
-- what the app hands the editor of every game, however that game lays it out
export type Properties = RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	IsSaving: boolean?,
	IsRandomizable: boolean?, -- a layout with a button for it only shows it when there's something to roll the draft
	FilteredText: FilteredText?,
	OnAction: (ActionInfo) -> (),
}
export type Component = (props: Properties) -> React.ReactNode
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
