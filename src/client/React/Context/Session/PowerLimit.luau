--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(PowerDefinition.DEFAULT_LIMIT)
