--!strict
-- Services
-- Packages
-- Modules
-- Types
-- the browser of custom servers is opened from the mode screen + leads back to it
export type BootPhase = "Loading" | "ModeSelect" | "ServerBrowser" | "Intro" | "Playing"
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
-- a menu over the gameplay hud, one at most is open
export type PanelId = "Music" | "Actions" | "Database" | "Shop" | "Build"
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
