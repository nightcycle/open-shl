--!strict
-- Services
-- Packages
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
type IdentityKey = CharacterType.IdentityKey
type PowerGroup = PowerType.PowerGroup
type ScaleAxis = CharacterEditorType.ScaleAxis
type TextureGroupKey = AppearanceType.TextureGroupKey
-- where something sits on the square canvas of a page, in widths of it from its top left corner
export type Box = {
	Position: UDim2,
	Size: UDim2,
}
export type ArtInfo = {
	Image: string,
	Box: Box,
}
-- the tag that covers a heading drawn into the art
export type HeadingInfo = {
	Text: string,
	Box: Box,
	TextColor3: Color3?, -- the accent otherwise
}
-- a list holds the items of its folders, or the powers of its groups. a list with limbs holds one of them at a time,
-- whichever the application button of the page was stepped to
export type ListInfo = {
	Box: Box,
	Folders: { string }?,
	Limbs: { string }?,
	PowerGroups: { PowerGroup }?,
}
-- a round button that opens the picker for one color: a page's own, or a texture group of whatever is worn out of
-- its folders
export type SwatchInfo = {
	Image: string,
	Box: Box,
	Page: string?,
	Folders: { string }?,
	Group: TextureGroupKey?, -- the first color of the item otherwise
}
-- a button that's one picture while its tag is off + another while it's on. the picture is a square with the button
-- drawn across part of it: only that part takes a press, the rest of the square may lie over something else
export type ToggleInfo = {
	Page: string,
	Box: Box,
	HitBox: Box, -- where on the picture the button is drawn, in widths of the picture
	Image: string,
	SelectedImage: string,
}
-- a row of bars over the ones drawn into the art, a pick fills every bar up to its own
export type BarsInfo = {
	Page: string,
	Axis: ScaleAxis,
	Boxes: { Box },
}
-- a box that's typed into over a pill drawn into the art. one that names an identity is that identity's, whichever is
-- in front
export type EntryInfo = {
	Page: string,
	Box: Box,
	IdentityKey: IdentityKey?,
	TextSize: number?, -- scaled to its box otherwise
	TextColor3: Color3,
	PlaceholderColor3: Color3,
}
-- the row of what's picked out of the lists of powers
export type SlotsInfo = {
	Box: Box,
	SlotSize: number, -- in widths of the row
	Padding: number, -- in widths of the row
}
-- the button under a page that steps its list of limbs along
export type ApplicationInfo = {
	Art: ArtInfo,
	Box: Box,
}
export type TabInfo = {
	Key: string, -- the page of the game's editor it opens
	Caption: string,
	Icon: string,
	Art: string,
	IdentityKey: IdentityKey?, -- the identity it brings to the front, whoever is there stays otherwise
	Path: string?, -- the page whose own fields it shows
	Sidebars: { ArtInfo }?,
	Headings: { HeadingInfo },
	Lists: { ListInfo }?,
	Swatches: { SwatchInfo }?,
	Toggles: { ToggleInfo }?,
	Bars: { BarsInfo }?,
	Entries: { EntryInfo }?,
	Slots: SlotsInfo?,
	Application: ApplicationInfo?,
	Logo: ArtInfo?,
}
-- the color a picker is open for: an item's page or a page of its own, and the texture group on it
export type Focus = {
	Path: string,
	Group: TextureGroupKey?,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
