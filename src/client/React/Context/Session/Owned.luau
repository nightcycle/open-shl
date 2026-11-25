--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
export type Owned = EconomyType.Owned
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what the player has of what the game holds back at a price, nothing until the session says so
local DEFAULT: Owned = table.freeze({ ItemIds = table.freeze({}), PowerIds = table.freeze({}) })

return React.createContext(DEFAULT)
