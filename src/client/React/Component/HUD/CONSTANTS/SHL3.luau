--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
type Buttons = HUDTypes.Buttons
-- Constants
-- a square on the edge of the screen for every menu, each at the height the legacy place had it. the picture is the
-- whole button, so none has a color. there's nothing to build, so there's no build button
local BUTTONS: Buttons = {
	LEFT = {
		{
			MenuId = PseudoEnum.MenuId.Swap,
			Image = Image["shl-3"].ui.switch["open.png"],
			Position = 0.4986,
		},
		{
			MenuId = PseudoEnum.MenuId.Characters,
			Image = Image["shl-3"].ui["suit-manager"]["open.png"],
			Position = 0.6,
		},
	},
	-- the gaps are where the team change (0.6) + the mode changer (0.8) go once they have a menu
	RIGHT = {
		{
			MenuId = PseudoEnum.MenuId.Database,
			Image = Image["shl-3"].ui.info["open.png"],
			Position = 0.5,
		},
		{
			MenuId = PseudoEnum.MenuId.Shop,
			Image = Image["shl-3"].ui.shop["open.png"],
			Position = 0.7,
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return BUTTONS
