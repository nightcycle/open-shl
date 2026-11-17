--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
export type PanelId = ShellType.PanelId
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: PanelId?)
