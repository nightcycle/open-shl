--!strict
-- Services
-- Packages
-- Modules
local Cheeseburger = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Cheeseburger")
local Keycard = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Keycard")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type ClientDefinition = PropType.ClientDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the client halves of the props of shl3, one for every row its catalogue lists as built
local DEFINITIONS: { ClientDefinition } = {
	Keycard,
	Cheeseburger,
}

return table.freeze(DEFINITIONS)
