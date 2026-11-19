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
		Type: "Select",
		CharacterId: string,
	}
	| {
		Type: "Edit",
		CharacterId: string,
	}
	-- the pass that adds slots is asked for, only a layout that offers it says so
	| {
		Type: "BuySlots",
	}
	-- whoever is played is kept in this slot as well, in place of who was there. only a layout that offers it says so
	| {
		Type: "Copy",
		CharacterId: string,
	}
	| {
		Type: "Exit",
	}

-- what the app tells whatever draws the character select of its game
export type Properties = RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
}
-- a layout that takes all of that as it is
export type Component = (props: Properties) -> React.ReactNode
Types.Component = Type.callback
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
