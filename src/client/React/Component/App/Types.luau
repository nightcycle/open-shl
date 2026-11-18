--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type BootPhase = ShellType.BootPhase
type ScreenType = ShellType.ScreenType
type PanelId = ShellType.PanelId
local Types = {}

export type Container = (props: {}) -> React.ReactNode
Types.Container = Type.callback
-- the checker doesn't look into the slots, a container under a name there isn't would never be mounted
export type Registry = {
	-- what's under everything else for as long as the game is played
	HUD: HUDTypes.Component,
	BOOT_PHASES: { [BootPhase]: Container },
	SCREENS: { [ScreenType]: Container },
	PANELS: { [PanelId]: Container },
	-- always mounted, keyed by the name of their component
	OVERLAYS: { [string]: Container },
	-- the same, but drawn over the boot phases as well
	TOP_OVERLAYS: { [string]: Container },
}
Types.Registry = Type.strictInterface({
	HUD = HUDTypes.Component,
	BOOT_PHASES = Type.map(ShellType.BootPhase, Types.Container),
	SCREENS = Type.map(ShellType.ScreenType, Types.Container),
	PANELS = Type.map(ShellType.PanelId, Types.Container),
	OVERLAYS = Type.map(Type.string, Types.Container),
	TOP_OVERLAYS = Type.map(Type.string, Types.Container),
})
export type Layer = "BootPhase" | "Screen" | "Panel" | "Overlay" | "TopOverlay"
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
