--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local CharacterEditor =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterEditor")
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
	BOOT_PHASES = {},
	SCREENS = {
		CharacterEditor = CharacterEditor,
	},
	PANELS = {},
	OVERLAYS = {},
	TOP_OVERLAYS = {},
}
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
