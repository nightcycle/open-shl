--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type BootPhase = ShellType.BootPhase
type ScreenType = ShellType.ScreenType
type PanelId = ShellType.PanelId
export type Container = (props: {}) -> React.ReactNode
export type Registry = {
	BOOT_PHASES: { [BootPhase]: Container },
	SCREENS: { [ScreenType]: Container },
	PANELS: { [PanelId]: Container },
	-- always mounted, keyed by the name of their component
	OVERLAYS: { [string]: Container },
	-- the same, but drawn over the boot phases as well
	TOP_OVERLAYS: { [string]: Container },
}
export type Layer = "BootPhase" | "Screen" | "Panel" | "Overlay" | "TopOverlay"
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
