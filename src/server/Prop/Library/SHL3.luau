--!strict
-- Services
-- Packages
-- Modules
local Cheeseburger = require("@game/ServerScriptService/Server/Prop/Library/Cheeseburger")
local Keycard = require("@game/ServerScriptService/Server/Prop/Library/Keycard")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type ServerDefinition = PropType.ServerDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the server halves of the props of shl3, one for every row its catalogue lists as built
local DEFINITIONS: { ServerDefinition } = {
	Keycard,
	Cheeseburger,
}

return table.freeze(DEFINITIONS)
