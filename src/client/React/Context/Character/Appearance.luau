--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local Appearance = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type Appearance = Appearance.Appearance
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext({
	Items = {},
	HiddenTags = {},
})
