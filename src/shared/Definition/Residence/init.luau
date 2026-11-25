--!strict
-- Services
-- Packages
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local ResidenceType = require("@game/ReplicatedStorage/Shared/Type/Residence")
export type State = ResidenceType.State
type Wire = ResidenceType.Wire
-- Constants
-- which texts name a residence + what a client builds one from is the game's own. every game has an answer, the
-- remotes + the attribute that carry them are there in all three: a game without residences lets nothing through
local WIRE: Wire = GameDefinition.pick({
	shl1 = function(): Wire
		return require("@self/SHL1")
	end,
	shl2 = function(): Wire
		return require("@self/SHL2")
	end,
	shl3 = function(): Wire
		return require("@self/SHL3")
	end,
})
assert(ResidenceType.Wire(WIRE))
-- Variables
-- References
-- Private Functions
-- Class
return WIRE
