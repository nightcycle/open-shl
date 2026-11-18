--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
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
export type ScreenType = "None" | "CharacterSelect" | "CharacterEditor" | "ArtifactMenu"
Types.ScreenType = Type.literal("None", "CharacterSelect", "CharacterEditor", "ArtifactMenu")
-- a menu over the gameplay hud, one at most is open
export type PanelId = "Music" | "Actions" | "Database" | "Shop" | "Build"
Types.PanelId = Type.literal("Music", "Actions", "Database", "Shop", "Build")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
