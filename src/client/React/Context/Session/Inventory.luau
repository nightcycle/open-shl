--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
export type BaseInventory = BaseType.BaseInventory
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the furniture + themes the player owns, none until the session says so
local DEFAULT: BaseInventory = table.freeze({ FurnitureIds = table.freeze({}), ThemeIds = table.freeze({}) })

return React.createContext(DEFAULT)
