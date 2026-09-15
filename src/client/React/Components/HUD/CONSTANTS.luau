--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
export type ButtonInfo = {
	MenuId: PseudoEnum.MenuId,
	Image: string,
	BackgroundColor3: Color3,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {
	BUTTONS = {
		LEFT = {
			{
				MenuId = PseudoEnum.MenuId.Music,
				Image = Image.ui["music.png"],
				BackgroundColor3 = Color3.fromRGB(0, 198, 92),
			} :: ButtonInfo,
			{
				MenuId = PseudoEnum.MenuId.Database,
				Image = Image.ui["database.png"],
				BackgroundColor3 = Color3.fromRGB(0, 213, 255),
			},
			{
				MenuId = PseudoEnum.MenuId.Shop,
				Image = Image.ui["shop.png"],
				BackgroundColor3 = Color3.fromRGB(0, 80, 229),
			},
			{
				MenuId = PseudoEnum.MenuId.Camera,
				Image = Image.ui["camera.png"],
				BackgroundColor3 = Color3.fromRGB(145, 0, 229),
			},
		},
		RIGHT = {
			{
				MenuId = PseudoEnum.MenuId.Swap,
				Image = Image.ui["switch.png"],
				BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			} :: ButtonInfo,
			{
				MenuId = PseudoEnum.MenuId.Characters,
				Image = Image.ui["characters.png"],
				BackgroundColor3 = Color3.fromRGB(255, 140, 0),
			},
			{
				MenuId = PseudoEnum.MenuId.Actions,
				Image = Image.ui["settings.png"],
				BackgroundColor3 = Color3.fromRGB(255, 217, 0),
			},
			{
				MenuId = PseudoEnum.MenuId.Artifact,
				Image = Image.ui["hat.png"],
				BackgroundColor3 = Color3.fromRGB(169, 216, 0),
			},
		},
	},
}
