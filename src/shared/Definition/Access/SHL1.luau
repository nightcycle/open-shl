--!strict
-- Services
-- Packages
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type AccessCatalogue = EconomyType.AccessCatalogue
type Listing = EconomyType.Listing
type Lock = EconomyType.Lock
-- Constants
-- Variables
-- nothing here is sold for a currency. what's held back is what the lists of the old creator had past the ones
-- anybody could pick, behind the lock of its list: a pass or the group. it's written down where those lists are, the
-- items with their order + the powers with their slot, so this is only what the two of them say. every item + every
-- power is a listing of its own: a suit is held back limb by limb, one lock for all of them
local Listings: { Listing } = {}
-- References
-- Private Functions
-- a lock nothing could open would hold what's behind it back from everybody for good
local function assertOpenable(name: string, lock: Lock)
	if lock.Type == "Entitlement" then
		assert(
			ProductDefinition.getFromEntitlement(lock.Key).IsOk,
			`"{name}" is behind the "{lock.Id}" lock, the game sells no pass that hands out "{lock.Key}"`
		)
	else
		assert(ProductDefinition.GROUP_ID ~= nil, `"{name}" is behind the "{lock.Id}" lock, the game has no group`)
	end
end
-- Class
for _, definition in ItemAppearanceDefinition.listLocked() do
	local lock = definition.Lock
	if lock then
		local name = definition.Name or definition.Id
		assertOpenable(name, lock)
		table.insert(Listings, {
			Id = definition.Id,
			Name = name,
			ItemIds = { definition.Id },
			Lock = lock,
		})
	end
end
-- a power that's still on its way is held back from the day it's out: it's listed with its row
for _, definition in PowerDefinition.list() do
	local lock = PowerDefinition.getLock(definition.Id)
	if lock then
		assertOpenable(definition.Name, lock)
		table.insert(Listings, {
			Id = definition.Id,
			Name = definition.Name,
			PowerId = definition.Id,
			Lock = lock,
		})
	end
end

local CATALOGUE: AccessCatalogue = {
	PriceAdjust = 1,
	Currency = "Credits",
	Listings = Listings,
}

return CATALOGUE
