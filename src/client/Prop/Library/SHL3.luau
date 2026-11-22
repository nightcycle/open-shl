--!strict
-- Services
-- Packages
-- Modules
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type ClientDefinition = PropType.ClientDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the client halves of the props of shl3, one for every row its catalogue lists as built. none is yet
local DEFINITIONS: { ClientDefinition } = {}

return table.freeze(DEFINITIONS)
