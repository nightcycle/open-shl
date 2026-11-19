--!strict
-- Services
-- Packages
-- Modules
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
type Buttons = HUDTypes.Buttons
-- Constants
-- its hud has no picture to put on an edge: every way out of playing is a word in the one drawer it has, which is
-- laid out by whatever draws that drawer. so neither column holds a button + there's nothing to build
local BUTTONS: Buttons = {
	LEFT = {},
	RIGHT = {},
}
-- Variables
-- References
-- Private Functions
-- Class
return BUTTONS
