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
		Intro = require("@self/Intro"),
	},
	SCREENS = {
		CharacterSelect = require("@self/CharacterSelect"),
		CharacterEditor = require("@self/CharacterEditor"),
		ArtifactMenu = require("@self/ArtifactMenu"),
		ArtifactUnlock = require("@self/ArtifactUnlock"),
	},
	PANELS = {
		Music = require("@self/Music"),
		Actions = require("@self/Actions"),
		Database = require("@self/Database"),
		Shop = require("@self/Shop"),
		Build = require("@self/Build"),
	},
	OVERLAYS = {
		Tutorial = require("@self/Tutorial"),
		QuestBanner = require("@self/QuestBanner"),
		CurrencyPopup = require("@self/CurrencyPopup"),
		DailyReward = require("@self/DailyReward"),
		NameTag = require("@self/NameTag"),
		CombatFeedback = require("@self/CombatFeedback"),
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
