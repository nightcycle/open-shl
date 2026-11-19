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
-- what a game takes over is its own, so is what its import is held to: the stores of another game are never planted
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
