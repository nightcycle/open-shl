--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
local Types = {}

export type Mode = ServerType.Mode
export type ActionInfo =
	{
		Type: "ModePressed",
		Mode: Mode,
	}
	| {
		Type: "ServersPressed",
	}
	| {
		Type: "IdEntered",
		Id: string,
	}
export type Properties = RobloxComponents.FrameProperties & {
	IsLeaving: boolean, -- a choice was made: the buttons are off screen, they come back when it turns false
	Notice: string?, -- why the last choice fell through
	IdNotice: string?, -- an answer about the id that was entered, it's written into the id box
	OnAction: (ActionInfo) -> (),
}
-- how the choice is drawn is the game's own, every layout is told + tells the same. one without servers to browse
-- or an id box never reports either
export type Component = (props: Properties) -> React.ReactNode
Types.Component = Type.callback
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
