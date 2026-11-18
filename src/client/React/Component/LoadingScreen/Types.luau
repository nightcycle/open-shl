--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local Types = {}

export type ActionInfo = {
	Type: "Skip", -- the player doesn't want to wait for what's left
}
export type Properties = RobloxComponents.FrameProperties & {
	Progress: number, -- from 0 to 1
	OnAction: (ActionInfo) -> (),
}
-- how the wait is drawn is the game's own, every layout is told + tells the same. one that has to be sat through
-- never reports a skip
export type Component = (props: Properties) -> React.ReactNode
Types.Component = Type.callback
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
