--!strict
-- Services
-- Packages
-- Modules
local AcousticGuitar = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/AcousticGuitar")
local Cheeseburger = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Cheeseburger")
local ElectricGuitar = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/ElectricGuitar")
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
	ElectricGuitar,
	AcousticGuitar,
}

return table.freeze(DEFINITIONS)
