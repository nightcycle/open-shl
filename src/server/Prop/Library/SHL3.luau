--!strict
-- Services
-- Packages
-- Modules
local AcousticGuitar = require("@game/ServerScriptService/Server/Prop/Library/AcousticGuitar")
local Cheeseburger = require("@game/ServerScriptService/Server/Prop/Library/Cheeseburger")
local ElectricGuitar = require("@game/ServerScriptService/Server/Prop/Library/ElectricGuitar")
local Keycard = require("@game/ServerScriptService/Server/Prop/Library/Keycard")
local Pizza = require("@game/ServerScriptService/Server/Prop/Library/Pizza")
local PizzaBox = require("@game/ServerScriptService/Server/Prop/Library/PizzaBox")
local Watermelon = require("@game/ServerScriptService/Server/Prop/Library/Watermelon")
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
	ElectricGuitar,
	AcousticGuitar,
	PizzaBox,
	Pizza,
	Watermelon,
}

return table.freeze(DEFINITIONS)
