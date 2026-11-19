--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local CharacterEditor =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterEditor")
local CharacterSelect =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterSelect")
local Loading = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Loading")
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/NameTag")
local Rules = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Rules")
local ServerId = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/ServerId")
-- Hooks
-- Contexts
-- Types
local AppTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Types")
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
type Registry = AppTypes.Registry
-- Constants
-- the screens of the first game are its own: a slot is listed once its own layout fills it, never with the kit of
-- another game in the meantime. a slot that isn't listed shows nothing
local REGISTRY: Registry = {
	-- stub: the drawer it kept its buttons in isn't built yet, nothing is drawn where a hud goes
	HUD = function(_: HUDTypes.Properties): React.ReactNode
		return nil
	end,
	BOOT_PHASES = {
		Loading = Loading,
		-- it flies nobody in: where another game does that its rules are read, on every join
		Intro = Rules,
	},
	SCREENS = {
		CharacterSelect = CharacterSelect,
		CharacterEditor = CharacterEditor,
	},
	PANELS = {},
	OVERLAYS = {
		NameTag = NameTag,
		ServerId = ServerId,
	},
	TOP_OVERLAYS = {},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
