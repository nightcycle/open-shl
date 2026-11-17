--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
local ADJECTIVES: { string } = table.freeze({
	"Red",
	"Orange",
	"Yellow",
	"Green",
	"Blue",
	"Violet",
	"Big",
	"Captain",
	"Doctor",
	"Agent",
	"Night",
	"Twilight",
	"Morning",
	"Royal",
	"Solar",
	"Lunar",
})
local NOUNS: { string } = table.freeze({
	"Avenger",
	"Crusader",
	"One",
	"Ghost",
	"Spirit",
	"Titan",
	"Sparrow",
	"Assassin",
	"Wizard",
	"Eagle",
	"Spider",
	"Hawk",
	"Shadow",
	"Stranger",
	"Vindicator",
	"Slayer",
	"Phoenix",
	"Spectre",
	"Wraith",
	"Marauder",
	"Falcon",
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

function Module.get(seed: number): string
	local rng = Random.new(seed)
	local adjective = ADJECTIVES[rng:NextInteger(1, #ADJECTIVES)]
	local noun = NOUNS[rng:NextInteger(1, #NOUNS)]
	return `{adjective} {noun}`
end

return Module
