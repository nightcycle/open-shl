--!strict
-- Services
-- Packages
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type ShopTab = EconomyType.ShopTab
export type TabInfo = {
	Tab: ShopTab,
	Text: string,
	BackgroundColor3: Color3,
	CardColor3: Color3,
	RowPositions: { number }, -- in scale of the panel
	Note: string?, -- takes the row after the last card
}
-- Constants
local ROW_POSITIONS = table.freeze({ 0.01, 0.17, 0.34, 0.5, 0.67, 0.84 })
-- Variables
-- References
-- Private Functions
-- Class
return {
	TABS = {
		{
			Tab = "Credits",
			Text = "Super Credits",
			BackgroundColor3 = Color3.fromRGB(0, 170, 0),
			CardColor3 = Color3.fromRGB(0, 170, 0),
			RowPositions = ROW_POSITIONS,
		} :: TabInfo,
		{
			Tab = "Gems",
			Text = "Power Gems",
			BackgroundColor3 = Color3.fromRGB(255, 85, 0),
			CardColor3 = Color3.fromRGB(255, 88, 88),
			RowPositions = ROW_POSITIONS,
		},
		{
			Tab = "Artifacts",
			Text = "Artifacts",
			BackgroundColor3 = Color3.fromRGB(0, 85, 255),
			CardColor3 = Color3.fromRGB(123, 35, 255),
			RowPositions = ROW_POSITIONS,
			Note = "Artifacts are unique textured accessories. Certain artifacts are rarer than others. You may customize your characters with artifacts.",
		},
		{
			Tab = "Gamepasses",
			Text = "Gamepasses",
			BackgroundColor3 = Color3.fromRGB(154, 0, 115),
			CardColor3 = Color3.fromRGB(154, 0, 115),
			RowPositions = table.freeze({ 0, 0.14, 0.28 }),
		},
	},
}
