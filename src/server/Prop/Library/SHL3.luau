--!strict
-- Services
-- Packages
-- Modules
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type ServerDefinition = PropType.ServerDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the server halves of the props of shl3, one for every row its catalogue lists as built. none is yet
local DEFINITIONS: { ServerDefinition } = {}

return table.freeze(DEFINITIONS)
