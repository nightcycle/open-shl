--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
type TestMap = SimpleTest.TestMap
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a session is walked the way the saves of its game go: what a new player starts out with + what the game before it
-- left them are the game's own. the walk of another game is never required, so what it plants + what it reads
-- doesn't have to be in the place
return GameDefinition.pick({
	shl1 = function(): TestMap
		return require("@self/SHL1")
	end,
	shl2 = function(): TestMap
		return require("@self/SHL2")
	end,
	shl3 = function(): TestMap
		return require("@self/SHL3")
	end,
})
