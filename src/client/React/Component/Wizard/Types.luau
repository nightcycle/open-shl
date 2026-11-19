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
-- a bar with an arrow at each end that steps through the items of one list of the game's editor, by the path of the
-- list. what's stepped to is worn at once
export type RowInfo = {
	Text: string,
	Folder: string,
	Position: UDim2,
}
-- a line of a page that has no panel to say it on
export type LineInfo = {
	Text: string,
	Box: Box,
	IsBold: boolean?,
	IsWarning: boolean?, -- written in the yellow of a title
}
-- a cover hides the booth + only says something. rows step through lists of items, a palette is the grid of colors: a
-- press on one is the way on. a plain page is the two panels + its button, for a page whose controls aren't built yet
export type PageKind = "Cover" | "Rows" | "Palette" | "Plain"
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
