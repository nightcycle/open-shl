--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local Types = {}

-- the browser of custom servers is opened from the mode screen + leads back to it
export type BootPhase = "Loading" | "ModeSelect" | "ServerBrowser" | "Intro" | "Playing"
Types.BootPhase = Type.literal("Loading", "ModeSelect", "ServerBrowser", "Intro", "Playing")
-- a full screen menu, replaces the gameplay hud while open
export type Screen =
	{
		Type: "None",
	}
	| {
		Type: "CharacterSelect",
	}
	| {
		Type: "CharacterEditor",
		CharacterId: string, -- the slot that gets edited
	}
	| {
		Type: "ArtifactMenu",
	}
Types.Screen = Type.union(
	Type.strictInterface({
		Type = Type.literal("None"),
	}),
	Type.strictInterface({
		Type = Type.literal("CharacterSelect"),
	}),
	Type.strictInterface({
		Type = Type.literal("CharacterEditor"),
		CharacterId = Type.string,
	}),
	Type.strictInterface({
		Type = Type.literal("ArtifactMenu"),
	})
)
export type ScreenType = "None" | "CharacterSelect" | "CharacterEditor" | "ArtifactMenu"
Types.ScreenType = Type.literal("None", "CharacterSelect", "CharacterEditor", "ArtifactMenu")
-- a menu over the gameplay hud, one at most is open
export type PanelId = "Music" | "Actions" | "Database" | "Shop" | "Build"
Types.PanelId = Type.literal("Music", "Actions", "Database", "Shop", "Build")
-- a phase a game goes through on the way in. the browser isn't one, it's a side room of the mode screen, + what
-- follows the last one is the game itself
export type Stop = "Loading" | "ModeSelect" | "Intro"
Types.Stop = Type.literal("Loading", "ModeSelect", "Intro")
-- what a button of the hud leads to: a menu of the shell, or something that's somebody else's to carry out
export type MenuAction =
	{
		Type: "Panel",
		PanelId: PanelId,
	}
	| {
		Type: "Screen",
		Screen: Screen,
	}
	| {
		Type: "CameraMode",
	}
	| {
		Type: "Swap",
	}
Types.MenuAction = Type.union(
	Type.strictInterface({
		Type = Type.literal("Panel"),
		PanelId = Types.PanelId,
	}),
	Type.strictInterface({
		Type = Type.literal("Screen"),
		Screen = Types.Screen,
	}),
	Type.strictInterface({
		Type = Type.literal("CameraMode"),
	}),
	Type.strictInterface({
		Type = Type.literal("Swap"),
	})
)
-- the way into a game + what's reached from its hud
export type Flow = {
	-- in order, the shell starts out in the first
	Stops: { Stop },
	-- the screen the boot ends on. a game without one ends on its hud, as whoever the server picked
	FirstScreen: Screen?,
	-- a button without a row does nothing
	Menu: { [PseudoEnum.MenuId]: MenuAction },
}
Types.Flow = Type.strictInterface({
	Stops = Type.array(Types.Stop),
	FirstScreen = Type.optional(Types.Screen),
	Menu = Type.map(Type.literal(table.unpack(PseudoEnum.getEnumItems("MenuId"))), Types.MenuAction),
})
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
