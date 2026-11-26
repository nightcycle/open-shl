--!strict
-- Services
-- Packages
-- Modules
local IconDefinitionConstructor = require("@game/ReplicatedStorage/Shared/Constructor/IconDefinition")
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type PropCatalogue = PropType.PropCatalogue
type PropDefinition = PropType.PropDefinition
-- Constants
-- what the roleplay pads of the city hand out. only the card ever had a picture, the hotbar spells the rest out
local DEFINITIONS: { PropDefinition } = {
	-- it does nothing by itself: the gates of the prison ask who holds one
	{
		Id = "keycard",
		Name = "Keycard",
		Icon = IconDefinitionConstructor.decal(Image["shl-3"].tools["keycard.png"]),
	},
	-- a bite takes as long as it keeps the next one off
	{ Id = "cheeseburger", Name = "Cheeseburger", Use = { Duration = 0.8 } },
	-- carried + nothing more: a click with one of these is nothing
	{ Id = "electric-guitar", Name = "Electric Guitar" },
	{ Id = "acoustic-guitar", Name = "Acoustic Guitar" },
	{ Id = "pizza-box", Name = "Pizza Box" },
	-- eaten a bite at a time, the way the burger is
	{ Id = "pizza", Name = "Pizza", Use = { Duration = 0.8 } },
	{ Id = "watermelon", Name = "Watermelon", Use = { Duration = 0.8 } },
	-- a drink is for show, it gives nothing
	{ Id = "bloxy-cola", Name = "Bloxy Cola", Use = { Duration = 3 } },
	-- a sip, then a minute before the next
	{ Id = "latte", Name = "Latte", Use = { Duration = 3, Lockout = 63 } },
	{ Id = "bloxiade", Name = "Bloxiade", Use = { Duration = 3, Lockout = 63 } },
	-- a flick + a second before the next: it turns on long after
	{ Id = "fidget-spinner", Name = "Fidget Spinner", Use = { Duration = 1 } },
	-- a handful of bills thrown about, for show: it pays nothing
	{ Id = "moneybag", Name = "Moneybag", Use = { Duration = 0.8 } },
	-- a lick of half a second: one that comes within 2 s of the last hurts
	{ Id = "ice-cream", Name = "Ice Cream", Use = { Duration = 0.5 } },
	-- held + nothing more to the server: its holder has its screen up
	{ Id = "tablet", Name = "Tablet" },
	-- a click casts the line, the next reels it in
	{ Id = "fishing-pole", Name = "Fishing Pole", Use = { Duration = 0.5 } },
}
-- none is left. a row waits here until both halves of its prop are in the game's set: nobody is handed one
local UPCOMING: { PropDefinition } = {}
-- the five that didn't come back: their pads are still on the map
local RETIRED: { string } = { "Hand Console", "Hot Dog", "Binoculars", "Hoverboard", "Boombox" }
local CATALOGUE: PropCatalogue = {
	Definitions = DEFINITIONS,
	Upcoming = UPCOMING,
	Retired = RETIRED,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
