--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
export type BaseInventory = BaseType.BaseInventory
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the furniture + themes the player owns
return React.createContext(BaseConstructor.newInventory())
