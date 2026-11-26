--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local OwnerUtil = require("@game/ServerScriptService/Server/Service/VipServer/Owner")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
-- Constants
local SERVER_ID = "a-private-server"
local OWNER_ID = 5
-- Variables
-- References
-- Private Functions
-- Class
-- the one rule the toggle of a private server hangs on. it's pure, so every game holds it to this
local Tests: TestMap = {
	-- only a server somebody bought has an owner
	Owned = SpecUtil.newScenario(function()
		assert(not OwnerUtil.getIfOwned("", 0), `a public server is owned`)
		assert(not OwnerUtil.getIfOwned(SERVER_ID, 0), `a server the game reserved is owned`)
		assert(not OwnerUtil.getIfOwned("", OWNER_ID), `an owner without a server makes one owned`)
		assert(OwnerUtil.getIfOwned(SERVER_ID, OWNER_ID), `a server somebody bought isn't owned`)
	end),

	-- + only that somebody is its owner
	Owner = SpecUtil.newScenario(function()
		assert(not OwnerUtil.getIfOwner("", 0, OWNER_ID), `a public server has an owner`)
		assert(not OwnerUtil.getIfOwner(SERVER_ID, 0, OWNER_ID), `a server the game reserved has an owner`)
		assert(OwnerUtil.getIfOwner(SERVER_ID, OWNER_ID, OWNER_ID), `the owner isn't the owner`)
		assert(not OwnerUtil.getIfOwner(SERVER_ID, OWNER_ID, OWNER_ID + 1), `somebody else is the owner`)
		assert(not OwnerUtil.getIfOwner("", OWNER_ID, OWNER_ID), `an owner without a server is one`)
	end),

	-- what the engine says for nobody matches no player, whatever id one claims to have
	Nobody = SpecUtil.newScenario(function()
		assert(not OwnerUtil.getIfOwner(SERVER_ID, 0, 0), `nobody owns a server nobody owns`)
		assert(not OwnerUtil.getIfOwner(SERVER_ID, -1, -1), `an id below zero is an owner`)
		assert(not OwnerUtil.getIfOwner(SERVER_ID, OWNER_ID, 0), `an id of zero is the owner`)
		assert(not OwnerUtil.getIfOwner(SERVER_ID, OWNER_ID, -OWNER_ID), `an id below zero is the owner`)
	end),
}

return Tests
