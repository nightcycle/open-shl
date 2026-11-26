--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type EntitlementKey = EconomyType.EntitlementKey
type Lock = EconomyType.Lock
type Owned = EconomyType.Owned
type TestMap = SimpleTest.TestMap
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what a game holds back is its own, so is what its listings are held to. the walk of another game is never required
local Tests: TestMap = table.clone(GameDefinition.pick({
	shl1 = function(): TestMap
		return require("@self/SHL1")
	end,
	shl2 = function(): TestMap
		return {}
	end,
	shl3 = function(): TestMap
		return require("@self/SHL3")
	end,
}))

-- a lock opens to what it names + to nothing else, whatever was bought
Tests.Locks = SpecUtil.newScenario(function()
	local pass: Lock = { Id = "hat", Type = "Entitlement", Key = "PremiumMasks" }
	local group: Lock = { Id = "emblem", Type = "GroupPerk" }
	local nothing: Owned = { ItemIds = {}, PowerIds = {} }
	local other: Owned =
		{ ItemIds = {}, PowerIds = {}, Entitlements = { "PremiumHair" :: EntitlementKey }, HasGroupPerk = false }
	local both: Owned = {
		ItemIds = {},
		PowerIds = {},
		Entitlements = { "PremiumHair" :: EntitlementKey, "PremiumMasks" },
		HasGroupPerk = true,
	}
	assert(not AccessDefinition.getIfOpen(pass, nothing), `a pass opened to no entitlement at all`)
	assert(not AccessDefinition.getIfOpen(pass, other), `a pass opened to another pass`)
	assert(AccessDefinition.getIfOpen(pass, both), `a pass stayed shut to whoever has it`)
	assert(not AccessDefinition.getIfOpen(group, nothing), `the lock of the group opened to somebody never seen in it`)
	assert(not AccessDefinition.getIfOpen(group, other), `the lock of the group opened to a pass`)
	assert(AccessDefinition.getIfOpen(group, both), `the lock of the group stayed shut to a member`)
end)

-- what no listing holds back is anybody's
Tests.Unlisted = SpecUtil.newScenario(function()
	local nothing: Owned = { ItemIds = {}, PowerIds = {} }
	assert(AccessDefinition.getOf("no_such_thing") == nil, `something that isn't there is listed`)
	assert(AccessDefinition.getAccess("no_such_thing").Type == "Free", `what isn't listed isn't free`)
	assert(AccessDefinition.getIfOwned(nothing, "no_such_thing"), `what isn't listed isn't anybody's`)
	assert(
		#AccessDefinition.getUnowned(CharacterConstructor.new(), nothing) == 0,
		`a character that holds nothing is short of something`
	)
end)

return Tests
