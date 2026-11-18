--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local Types = {}

export type ActionInfo =
	{
		Type: "Purchase",
		ProductId: string,
	}
	| {
		Type: "Exit",
	}

-- what the app tells whatever draws the shop of its game
export type Properties = RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
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
