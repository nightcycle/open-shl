--!strict
-- Services
-- Packages
-- Modules
local AcousticGuitar = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/AcousticGuitar")
local Bloxiade = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Bloxiade")
local BloxyCola = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/BloxyCola")
local Cheeseburger = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Cheeseburger")
local ElectricGuitar = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/ElectricGuitar")
local FidgetSpinner = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/FidgetSpinner")
local FishingPole = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/FishingPole")
local IceCream = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/IceCream")
local Keycard = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Keycard")
local Latte = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Latte")
local Moneybag = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Moneybag")
local Pizza = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Pizza")
local PizzaBox = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/PizzaBox")
local Tablet = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/Tablet")
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
	Latte,
	Bloxiade,
	FidgetSpinner,
	Moneybag,
	IceCream,
	Tablet,
	FishingPole,
}

return table.freeze(DEFINITIONS)
