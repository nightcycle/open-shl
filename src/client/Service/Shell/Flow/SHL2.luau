--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type Flow = ShellType.Flow
-- Constants
-- a mode is picked where the place asks for one, then the avatar is flown in on. the boot ends on the hud, as
-- whoever the server picked, + every button of that hud has a menu
local FLOW: Flow = {
	Stops = { "Loading", "ModeSelect", "Intro" },
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
	-- it draws its own player list, health bar + emotes
	CoreGuis = { Enum.CoreGuiType.Chat },
}
-- Variables
-- References
-- Private Functions
-- Class
return FLOW
