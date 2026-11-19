--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type Flow = ShellType.Flow
-- Constants
-- the way in of the second game, with one more step at the end of it
local FLOW: Flow = {
	Stops = { "Loading", "ModeSelect", "Intro" },
	-- who to play as is picked on every join, its legacy place opened the character manager the same way
	FirstScreen = {
		Type = "CharacterSelect",
	},
	-- every button the shell knows leads where it does in the second game. a menu that isn't built for this one has
	-- no slot in its registry, so its button opens nothing
	Menu = {
		[PseudoEnum.MenuId.Music] = {
			Type = "Panel",
			PanelId = "Music",
		},
		[PseudoEnum.MenuId.Actions] = {
			Type = "Panel",
			PanelId = "Actions",
		},
		[PseudoEnum.MenuId.Database] = {
			Type = "Panel",
			PanelId = "Database",
		},
		[PseudoEnum.MenuId.Shop] = {
			Type = "Panel",
			PanelId = "Shop",
		},
		[PseudoEnum.MenuId.Build] = {
			Type = "Panel",
			PanelId = "Build",
		},
		[PseudoEnum.MenuId.Camera] = {
			Type = "CameraMode",
		},
		[PseudoEnum.MenuId.Swap] = {
			Type = "Swap",
		},
		[PseudoEnum.MenuId.Characters] = {
			Type = "Screen",
			Screen = {
				Type = "CharacterSelect",
			},
		},
		[PseudoEnum.MenuId.Artifact] = {
			Type = "Screen",
			Screen = {
				Type = "ArtifactMenu",
			},
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return FLOW
