--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local Types = {}

export type ButtonInfo = {
	MenuId: PseudoEnum.MenuId,
	Image: string, -- an image that isn't in the asset table is one the checker lets through
	BackgroundColor3: Color3?, -- left out where the picture is the whole button
	-- how far down the screen it sits in scale of it, for a hud that puts every button at a height of its own
	Position: number?,
}
Types.ButtonInfo = Type.strictInterface({
	MenuId = Type.literal(table.unpack(PseudoEnum.getEnumItems("MenuId"))),
	Image = Type.string,
	BackgroundColor3 = Type.optional(Type.Color3),
	Position = Type.optional(Type.numberConstrained(0, 1)),
})

-- what a game puts on its hud. a column is listed top to bottom
export type Buttons = {
	LEFT: { ButtonInfo },
	RIGHT: { ButtonInfo },
	BUILD: ButtonInfo?, -- a game that has nothing to build goes without
}
Types.Buttons = Type.strictInterface({
	LEFT = Type.array(Types.ButtonInfo),
	RIGHT = Type.array(Types.ButtonInfo),
	BUILD = Type.optional(Types.ButtonInfo),
})

-- what the app tells whatever draws the hud of its game
export type Properties = RobloxComponents.FrameProperties & {
	OnClick: (PseudoEnum.MenuId) -> (),
	IsBuildVisible: boolean?,
	IsCameraMode: boolean?, -- only the faded camera button is left, it's the way back out
	IsCameraHidden: boolean?,
	IsHealthVisible: boolean?,
	IsEnergyVisible: boolean?,
}
-- a layout that takes all of that as it is, or a container around a layout that asks for something else
export type Component = (props: Properties) -> React.ReactNode
Types.Component = Type.callback
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
