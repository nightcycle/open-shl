--!strict
-- Services
-- Packages
-- Modules
-- Components
-- Hooks
-- Contexts
-- Types
local AppTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Types")
type Registry = AppTypes.Registry
-- Constants
local REGISTRY: Registry = {
	BOOT_PHASES = {
		Loading = require("@self/Loading"),
		ModeSelect = require("@self/ModeSelect"),
		ServerBrowser = require("@self/ServerBrowser"),
		Intro = require("@self/Intro"),
	},
	SCREENS = {
		CharacterSelect = require("@self/CharacterSelect"),
		CharacterEditor = require("@self/CharacterEditor"),
		ArtifactMenu = require("@self/ArtifactMenu"),
	},
	PANELS = {
		Music = require("@self/Music"),
		Actions = require("@self/Actions"),
		Database = require("@self/Database"),
		Shop = require("@self/Shop"),
		Build = require("@self/Build"),
	},
	OVERLAYS = {
		QuestBanner = require("@self/QuestBanner"),
		CurrencyPopup = require("@self/CurrencyPopup"),
		DailyReward = require("@self/DailyReward"),
		NameTag = require("@self/NameTag"),
		CombatFeedback = require("@self/CombatFeedback"),
		ServerId = require("@self/ServerId"),
	},
	TOP_OVERLAYS = {
		-- the captain has a word to say about the mode screen as well
		Tutorial = require("@self/Tutorial"),
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
