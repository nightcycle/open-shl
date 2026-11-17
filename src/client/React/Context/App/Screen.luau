--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
export type Screen = ShellType.Screen
export type ScreenType = ShellType.ScreenType
-- Constants
local NONE: Screen = table.freeze({
	Type = "None" :: "None",
})
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(NONE)
