--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
-- Constants
-- what the lists of the old creator had past the ones anybody could pick: how many pieces are behind each lock, the
-- pass that opens it + what a visit with one costs. a suit is six pieces on each of five limbs behind one lock
local LOCKS: { [string]: { Count: number, Key: string?, RentPrice: number? } } = {
	face = { Count = 6, Key = "PremiumFaces", RentPrice = 20 },
	hair = { Count = 10, Key = "PremiumHair", RentPrice = 20 },
	hat = { Count = 9, Key = "PremiumMasks", RentPrice = 25 },
	suit = { Count = 30, Key = "PremiumSuits", RentPrice = 25 },
	emblem = { Count = 3 },
}
-- the lock of each slot of powers, by the id of the slot
local POWER_LOCK_IDS: { string } = table.freeze({ "melee", "ranged", "special" })
local POWER_RENT_PRICE = 30
-- Variables
-- References
-- Private Functions
-- Class
local Tests: TestMap = {}

-- every piece past the starters of its list is behind the lock of that list, + nothing else is
Tests.Lists = SpecUtil.newScenario(function()
	local counts: { [string]: number } = {}
	for _, definition in ItemAppearanceDefinition.list() do
		local lock = definition.Lock
		local listing = AccessDefinition.getOf(definition.Id)
		if not lock then
			assert(listing == nil, `"{definition.Id}" has no lock + is listed`)
			continue
		end
		assert(definition.IsStarter == false, `"{definition.Id}" is a starter behind a lock`)
		assert(listing ~= nil and listing.Lock == lock, `"{definition.Id}" isn't listed behind its lock`)
		local expected = LOCKS[lock.Id]
		assert(expected, `"{definition.Id}" is behind a lock nobody knows: "{lock.Id}"`)
		if lock.Type == "Entitlement" then
			assert(lock.Key == expected.Key, `the "{lock.Id}" lock is opened by "{lock.Key}"`)
			assert(lock.RentPrice == expected.RentPrice, `the "{lock.Id}" lock rents at {tostring(lock.RentPrice)}`)
		else
			assert(expected.Key == nil, `the "{lock.Id}" lock is the group's`)
		end
		counts[lock.Id] = (counts[lock.Id] or 0) + 1
	end
	for id, expected in LOCKS do
		assert(counts[id] == expected.Count, `{tostring(counts[id])} pieces are behind the "{id}" lock`)
	end
end)

-- a power past the starters of its slot is behind the lock of that slot, out or not. only one that's out is listed
Tests.Slots = SpecUtil.newScenario(function()
	local lockedCount = 0
	for _, definition in PowerDefinition.list() do
		local lock = PowerDefinition.getLock(definition.Id)
		local listing = AccessDefinition.getOf(definition.Id)
		if not lock then
			assert(listing == nil, `"{definition.Id}" has no lock + is listed`)
			continue
		end
		lockedCount += 1
		assert(table.find(POWER_LOCK_IDS, lock.Id) ~= nil, `"{definition.Id}" is behind "{lock.Id}"`)
		assert(
			lock.Type == "Entitlement" and lock.Key == "PremiumPowers" and lock.RentPrice == POWER_RENT_PRICE,
			`the lock of "{definition.Id}" isn't the pass of the powers at {POWER_RENT_PRICE}`
		)
		assert(listing ~= nil and listing.PowerId == definition.Id, `"{definition.Id}" is out + isn't listed`)
	end
	local listedCount = 0
	for _, listing in AccessDefinition.list() do
		listedCount += if listing.PowerId then 1 else 0
	end
	assert(listedCount == lockedCount, `{listedCount} powers are listed, {lockedCount} that are out are locked`)
end)

return Tests
