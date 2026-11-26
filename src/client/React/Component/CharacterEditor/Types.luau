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
		Character: Character, -- the draft as it is, what a roll leaves alone is taken from it
	}
	| {
		-- asks for what stands between the player + an item or a power of the game: to buy what it's sold as, or
		-- the pass it's behind
		Type: "Purchase",
		Id: string,
	}
	| {
		Type: "CheckGroupPerk", -- asks for the server to look anew whether the player is in the group of the game
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
	Draft: Character?, -- what the layout is to go on editing in place of its draft, each time it's handed another
	IsPeaceful: boolean?, -- set while the player sits fights out, for a layout that asks whether they do
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
