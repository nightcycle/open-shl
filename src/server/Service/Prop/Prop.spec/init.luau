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
-- what the server runs of a prop is walked with the props of its game: the numbers a walk holds them to are the
-- game's own. a game that hands none out has nothing to hold this to
return GameDefinition.pick({
	shl1 = function(): TestMap
		return {}
	end,
	shl2 = function(): TestMap
		return {}
	end,
	shl3 = function(): TestMap
		return require("@self/SHL3")
	end,
})
