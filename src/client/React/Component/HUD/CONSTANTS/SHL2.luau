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
local BUTTONS: Buttons = {
	LEFT = {
		{
			MenuId = PseudoEnum.MenuId.Music,
			Image = Image["shl-2"].ui["music.png"],
			BackgroundColor3 = Color3.fromRGB(0, 198, 92),
		},
		{
			MenuId = PseudoEnum.MenuId.Database,
			Image = Image["shl-2"].ui["database.png"],
			BackgroundColor3 = Color3.fromRGB(0, 213, 255),
		},
		{
			MenuId = PseudoEnum.MenuId.Shop,
			Image = Image["shl-2"].ui["shop.png"],
			BackgroundColor3 = Color3.fromRGB(0, 80, 229),
		},
		{
			MenuId = PseudoEnum.MenuId.Camera,
			Image = Image["shl-2"].ui["camera.png"],
			BackgroundColor3 = Color3.fromRGB(145, 0, 229),
		},
	},
	RIGHT = {
		{
			MenuId = PseudoEnum.MenuId.Swap,
			Image = Image["shl-2"].ui["switch.png"],
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		},
		{
			MenuId = PseudoEnum.MenuId.Characters,
			Image = Image["shl-2"].ui["characters.png"],
			BackgroundColor3 = Color3.fromRGB(255, 140, 0),
		},
		{
			MenuId = PseudoEnum.MenuId.Actions,
			Image = Image["shl-2"].ui["settings.png"],
			BackgroundColor3 = Color3.fromRGB(255, 217, 0),
		},
		{
			MenuId = PseudoEnum.MenuId.Artifact,
			Image = Image["shl-2"].ui["hat.png"],
			BackgroundColor3 = Color3.fromRGB(169, 216, 0),
		},
	},
	BUILD = {
		MenuId = PseudoEnum.MenuId.Build,
		Image = Image["shl-2"].ui["build.png"],
		BackgroundColor3 = Color3.fromRGB(135, 0, 203),
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return BUTTONS
