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
-- the converter reads what the game before superhero life 2 stored. no other game runs it, so there's nothing of it
-- to hold them to + the suits it's tested on don't have to be in their places
return GameDefinition.pick({
	shl1 = function(): TestMap
		return {}
	end,
	shl2 = function(): TestMap
		return require("@self/SHL2")
	end,
	shl3 = function(): TestMap
		return {}
	end,
})
