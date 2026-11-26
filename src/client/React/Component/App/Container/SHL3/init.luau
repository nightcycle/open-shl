--!strict
-- Services
-- Packages
-- Modules
-- Components
local AlertStrip = require("@self/AlertStrip")
local ApartmentSale = require("@self/ApartmentSale")
local CharacterEditor =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterEditor")
local CharacterSelect =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterSelect")
local CombatFeedback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CombatFeedback")
local CurrencyPopup =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CurrencyPopup")
local EdgeHUD = require("@self/EdgeHUD")
local FlyIn = require("@self/FlyIn")
local JobMenu = require("@self/JobMenu")
local Loading = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Loading")
local ModeChanger = require("@self/ModeChanger")
local ModeSelect = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/ModeSelect")
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/NameTag")
local Notice = require("@self/Notice")
local PlayerBoard = require("@self/PlayerBoard")
local Shop = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Shop")
local StockHealth = require("@self/StockHealth")
local Tablet = require("@self/Tablet")
local TeamChange = require("@self/TeamChange")
-- Hooks
-- Contexts
-- Types
local AppTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Types")
type Registry = AppTypes.Registry
-- Constants
-- a slot another game fills as well is filled by the same container here: what a game has to itself is the layout that
-- container picks. the menus that aren't built for it yet have no slot, their button opens nothing
local REGISTRY: Registry = {
	HUD = EdgeHUD,
	BOOT_PHASES = {
		Loading = Loading,
		ModeSelect = ModeSelect,
		-- its intro is a flight along other way-points, with a screen that's told other things
		Intro = FlyIn,
	},
	SCREENS = {
		CharacterSelect = CharacterSelect,
		CharacterEditor = CharacterEditor,
		-- a pad of the map opens it, no button of the hud does
		JobMenu = JobMenu,
	},
	PANELS = {
		-- the list of who's in the game is what the shell calls a database, its hud has the button for it
		Database = PlayerBoard,
		Shop = Shop,
		-- only reached from a button its hud has where there are sides to change
		TeamChange = TeamChange,
		-- the salesman of the apartment tower opens it, no button of the hud does
		ApartmentSale = ApartmentSale,
		-- only reached from a button its hud has where there's another place of the game to go to
		ModeChanger = ModeChanger,
	},
	OVERLAYS = {
		CurrencyPopup = CurrencyPopup,
		NameTag = NameTag,
		CombatFeedback = CombatFeedback,
		-- it draws nothing: the health bar is the engine's, this keeps it on what the game says is left
		StockHealth = StockHealth,
		-- a line from the town, up over whatever else is
		AlertStrip = AlertStrip,
		-- a line for this player alone: what a prop does to whoever holds it
		Notice = Notice,
		-- the screen of the tablet, for as long as it's in the hand
		Tablet = Tablet,
	},
	TOP_OVERLAYS = {},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
