--!strict
-- Services
-- Packages
-- Modules
-- Components
local Acrobatics = require("@self/Acrobatics")
local CharacterEditor =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterEditor")
local CharacterSelect =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterSelect")
local CombatFeedback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CombatFeedback")
local Loading = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Loading")
local MenuDrawer = require("@self/MenuDrawer")
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/NameTag")
local Rules = require("@self/Rules")
local Shop = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Shop")
local Ticker = require("@self/Ticker")
-- Hooks
-- Contexts
-- Types
local AppTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Types")
type Registry = AppTypes.Registry
-- Constants
-- the screens of the first game are its own: a slot is listed once its own layout fills it, never with the kit of
-- another game in the meantime. a slot that isn't listed shows nothing
local REGISTRY: Registry = {
	-- its hud is one drawer of words on the left edge, with the balance + the way to the shop under the ticker
	HUD = MenuDrawer,
	BOOT_PHASES = {
		Loading = Loading,
		-- it flies nobody in: where another game does that its rules are read, on every join
		Intro = Rules,
	},
	SCREENS = {
		CharacterSelect = CharacterSelect,
		CharacterEditor = CharacterEditor,
	},
	PANELS = {
		Shop = Shop,
	},
	OVERLAYS = {
		-- the panel of flips, up with the hud while the hero is out
		Acrobatics = Acrobatics,
		-- it has no bar for its health: the flash of a hit is how a player sees one land
		CombatFeedback = CombatFeedback,
		NameTag = NameTag,
		Ticker = Ticker,
	},
	TOP_OVERLAYS = {},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
