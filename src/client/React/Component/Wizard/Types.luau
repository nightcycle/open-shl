--!strict
-- Services
-- Packages
-- Modules
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
-- where something sits on what holds it, in scale of that
export type Box = {
	Position: UDim2,
	Size: UDim2,
}
-- the button a page is left by. a card is the white box of a page without a panel, a bar the blue one of a panel
export type ForwardInfo = {
	Text: string,
	Box: Box,
	IsCard: boolean?,
}
-- what the arrows of a row step through, each a piece of the page of the game's editor the row is on. a list is named
-- by its path, a field by its place among the fields of its kind on the page
export type RowSource =
	{
		Type: "Items", -- the items of a list: what's stepped to is worn at once, in place of the one before
		Folder: string,
	}
	| {
		Type: "Sets", -- the sets of a list: every item of the one that's stepped to goes on
		Folder: string,
	}
	| {
		Type: "Extras", -- the items of a list more than one is worn of: what's stepped to is tried on, a button keeps it
		Folder: string,
	}
	| {
		Type: "Glow", -- the looks of a pattern field, which are two: either arrow is the switch
		Field: number,
	}
	| {
		Type: "Power", -- the powers of a list field: the one that's stepped to is held, + named under the row
		Field: number,
	}
	| {
		Type: "Choice", -- the choices of a choose field: the row reads the one that's picked
		Field: number,
	}
	| {
		Type: "Mode", -- whether the player fights, which is nothing of the character: the row reads it
	}
-- a bar with an arrow at each end. the rows under it hang on it + are placed in scale of it
export type RowInfo = {
	Text: string, -- what it's a row of, or what it reads until there's a pick to read
	Source: RowSource,
	Position: UDim2,
	Size: UDim2,
	IsNested: boolean?, -- drawn in the lighter blue of a row that hangs under another
	Rows: { RowInfo }?,
}
-- a bar that holds a box to type a name in, by the place of its field among the text fields of the page
export type NameInfo = {
	Field: number,
	Position: UDim2,
}
-- a line of a page that has no panel to say it on
export type LineInfo = {
	Text: string,
	Box: Box,
	IsBold: boolean?,
	IsWarning: boolean?, -- written in the yellow of a title
}
-- a cover hides the booth + only says something. rows step through what the page edits, a palette is the grid of
-- colors: a press on one is the way on. names are typed
export type PageKind = "Cover" | "Rows" | "Palette" | "Names"
export type PageInfo = {
	Key: string, -- the page of the game's editor it edits
	Kind: PageKind,
	IdentityKey: IdentityKey, -- who stands in the booth meanwhile
	-- a page is stopped on once for each of its titles: a palette asks for one color after the other
	Titles: { string },
	TitleBox: Box,
	PanelSize: UDim2?, -- how much of the screen the panel at the left takes, a cover has none
	Help: string?, -- what the panel at the right says
	Forward: ForwardInfo?, -- a palette has none
	Rent: Box?, -- where the button that isn't of use yet is drawn
	Rows: { RowInfo }?,
	Names: { NameInfo }?,
	Test: ForwardInfo?, -- the button that shows what the names read like to everybody else
	Lines: { LineInfo }?,
	IsSlidingOut: boolean?, -- the page after it comes up from under the screen, it's put there at once otherwise
}
-- one stop of the walk through the pages
export type Step = {
	Page: PageInfo,
	Index: number, -- which of the stops on its page it is
	Title: string,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
