--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: ItemDefinition?)
