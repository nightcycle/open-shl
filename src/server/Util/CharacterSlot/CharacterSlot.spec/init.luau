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
-- what a new player starts out with is the game's own, so is what it's held to
return GameDefinition.pick({
	shl1 = function(): TestMap
		return require("@self/SHL1")
	end,
	-- its starters are suits the game before it saved, the spec of their converter holds every one of them
	shl2 = function(): TestMap
		return {}
	end,
	shl3 = function(): TestMap
		return require("@self/SHL3")
	end,
})
