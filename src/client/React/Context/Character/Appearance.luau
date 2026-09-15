--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local Appearance = require("@game/ReplicatedStorage/Shared/Types/Appearance")
export type Appearance = Appearance.Appearance
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext({
	Items = {},
})
