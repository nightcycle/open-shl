--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
export type ButtonInfo = {
	MenuId: PseudoEnum.MenuId,
	SpriteKey: string,
	BackgroundColor3: Color3,
	Side: PseudoEnum.Side,
	LayoutOrder: number,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {
	BUTTONS = {
		{
			MenuId = PseudoEnum.MenuId.Music,
			BackgroundColor3 = Color3.fromRGB(0, 198, 92),
			LayoutOrder = 1,
		},
	} :: {},
}
