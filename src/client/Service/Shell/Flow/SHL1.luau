--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type Flow = ShellType.Flow
-- Constants
-- it's one place where who fights is each player's own pick, so no mode is picked on the way in whatever the place
-- was built with. it flies nobody in either: the phase another game does that in is where its rules are read
local FLOW: Flow = {
	Stops = { "Loading", "Intro" },
	-- a session of it started in its creator: a new suit or a saved one, asked on every join
	FirstScreen = {
		Type = "CharacterSelect",
	},
	-- the three words of its drawer that are menus of the shell. what the rest of them do is the drawer's own
	Menu = {
		[PseudoEnum.MenuId.Swap] = {
			Type = "Swap",
		},
		[PseudoEnum.MenuId.Characters] = {
			Type = "Screen",
			Screen = {
				Type = "CharacterSelect",
			},
		},
		[PseudoEnum.MenuId.Shop] = {
			Type = "Panel",
			PanelId = "Shop",
		},
	},
	-- it drew no health of its own, the bar of the engine was all there was to read it off
	CoreGuis = { Enum.CoreGuiType.Chat, Enum.CoreGuiType.Health },
	-- the list of players is where its columns are read, up with the hud
	HudCoreGuis = { Enum.CoreGuiType.PlayerList },
}
-- Variables
-- References
-- Private Functions
-- Class
return FLOW
