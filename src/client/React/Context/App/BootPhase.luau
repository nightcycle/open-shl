--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
export type BootPhase = ShellType.BootPhase
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext("Playing" :: BootPhase)
