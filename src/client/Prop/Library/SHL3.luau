--!strict
-- Services
-- Packages
-- Modules
local AcousticGuitar = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/AcousticGuitar")
local BloxyCola = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/BloxyCola")
local Cheeseburger = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Cheeseburger")
local ElectricGuitar = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/ElectricGuitar")
local Keycard = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Keycard")
local Pizza = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Pizza")
local PizzaBox = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/PizzaBox")
local Watermelon = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Watermelon")
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
	PizzaBox,
	Pizza,
	Watermelon,
	BloxyCola,
}

return table.freeze(DEFINITIONS)
