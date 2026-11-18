--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local Types = {}

-- what the app tells whatever shows a gain, how one is shown is the layout of the game
export type Properties = RobloxComponents.FrameProperties & {
	IsLoaded: boolean, -- balances that land before this aren't gains
}
export type Component = (props: Properties) -> React.ReactNode
Types.Component = Type.callback
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
