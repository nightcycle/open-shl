--!strict
-- Services
-- Packages
-- Modules
-- Components
local Actions = require("@self/Actions")
local ArtifactMenu = require("@self/ArtifactMenu")
local Build = require("@self/Build")
local CharacterEditor =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterEditor")
local CharacterSelect =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterSelect")
local CombatFeedback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CombatFeedback")
local CurrencyPopup =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CurrencyPopup")
local DailyReward = require("@self/DailyReward")
local Database = require("@self/Database")
local HUD = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD")
local Intro = require("@self/Intro")
local Loading = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Loading")
local ModeSelect = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/ModeSelect")
local Music = require("@self/Music")
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/NameTag")
local QuestBanner = require("@self/QuestBanner")
local ServerBrowser = require("@self/ServerBrowser")
local ServerId = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/ServerId")
local Shop = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Shop")
local Tutorial = require("@self/Tutorial")
-- Hooks
-- Contexts
-- Types
local AppTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Types")
type Registry = AppTypes.Registry
-- Constants
local REGISTRY: Registry = {
	HUD = HUD,
	BOOT_PHASES = {
		Loading = Loading,
		ModeSelect = ModeSelect,
		ServerBrowser = ServerBrowser,
		Intro = Intro,
	},
	SCREENS = {
		CharacterSelect = CharacterSelect,
		CharacterEditor = CharacterEditor,
		ArtifactMenu = ArtifactMenu,
	},
	PANELS = {
		Music = Music,
		Actions = Actions,
		Database = Database,
		Shop = Shop,
		Build = Build,
	},
	OVERLAYS = {
		QuestBanner = QuestBanner,
		CurrencyPopup = CurrencyPopup,
		DailyReward = DailyReward,
		NameTag = NameTag,
		CombatFeedback = CombatFeedback,
		ServerId = ServerId,
	},
	TOP_OVERLAYS = {
		-- the captain has a word to say about the mode screen as well
		Tutorial = Tutorial,
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
