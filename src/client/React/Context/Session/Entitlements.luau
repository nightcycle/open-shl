--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
export type EntitlementKey = EconomyType.EntitlementKey
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what the gamepasses of the player unlock
return React.createContext(table.freeze({}) :: { EntitlementKey })
