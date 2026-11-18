--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local Types = {}

export type ButtonInfo = {
	MenuId: PseudoEnum.MenuId,
	Image: string, -- an image that isn't in the asset table is one the checker lets through
	BackgroundColor3: Color3,
}
Types.ButtonInfo = Type.strictInterface({
	MenuId = Type.literal(table.unpack(PseudoEnum.getEnumItems("MenuId"))),
	Image = Type.string,
	BackgroundColor3 = Type.Color3,
})

-- what a game puts on its hud. a column is listed top to bottom
export type Buttons = {
	LEFT: { ButtonInfo },
	RIGHT: { ButtonInfo },
	BUILD: ButtonInfo,
}
Types.Buttons = Type.strictInterface({
	LEFT = Type.array(Types.ButtonInfo),
	RIGHT = Type.array(Types.ButtonInfo),
	BUILD = Types.ButtonInfo,
})
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
