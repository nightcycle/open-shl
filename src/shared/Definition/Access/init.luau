--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
export type Access = EconomyType.Access
export type Listing = EconomyType.Listing
export type Lock = EconomyType.Lock
export type Owned = EconomyType.Owned
type AccessCatalogue = EconomyType.AccessCatalogue
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
-- what a slot held before it was edited: each may stay where it was, owned or not. whoever asks may take ids out of
-- it before it's handed on
export type Kept = {
	PowerIds: { [string]: true },
	ItemIds: { [IdentityKey]: { [string]: true } },
}
-- Constants
-- prices come in whole hundreds, a cost is rounded up to the next one once it's adjusted
local PRICE_STEP = 100
local FREE: Access = table.freeze({ Type = "Free" :: "Free" })
-- the order a character is gone through in
local IDENTITY_KEYS: { IdentityKey } = table.freeze({ "Main" :: IdentityKey, "Secret" })
-- what's held back + how it's got is the game's own, the listings of another game are never required
local CATALOGUE: AccessCatalogue = GameDefinition.pick({
	shl1 = function(): AccessCatalogue
		return require("@self/SHL1")
	end,
	shl2 = function(): AccessCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): AccessCatalogue
		return require("@self/SHL3")
	end,
})
assert(EconomyType.AccessCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local LISTINGS = CATALOGUE.Listings
-- Variables
-- an item or a power is held back by one listing at most
local ListingsById: { [string]: Listing? } = {}
local ListingsByItemId: { [string]: Listing? } = {}
local ListingsByPowerId: { [string]: Listing? } = {}
local AccessByListing: { [Listing]: Access } = {}
-- References
-- Private Functions
local function newAccess(listing: Listing): Access
	local lock = listing.Lock
	if lock then
		return lock
	end
	return table.freeze({
		Type = "Price" :: "Price",
		Currency = CATALOGUE.Currency,
		Amount = math.ceil((listing.Cost or 0) * CATALOGUE.PriceAdjust / PRICE_STEP) * PRICE_STEP,
	})
end

local function getIfHeld(ids: { string }, id: string): boolean
	return table.find(ids, id) ~= nil
end
-- Class
local Module = {}

for _, listing in LISTINGS do
	assert(ListingsById[listing.Id] == nil, `duplicate listing "{listing.Id}"`)
	ListingsById[listing.Id] = listing
	AccessByListing[listing] = newAccess(listing)
	local itemIds: { string } = listing.ItemIds or {}
	for _, itemId in itemIds do
		-- an item the game has no place for is one nobody could ever put on
		assert(ItemAppearanceDefinition.getIndex(itemId).IsOk, `"{listing.Id}" lists "{itemId}", which is no item`)
		assert(ListingsByItemId[itemId] == nil, `the item "{itemId}" is listed twice`)
		ListingsByItemId[itemId] = listing
	end
	local powerId = listing.PowerId
	if powerId then
		-- a power that's still on its way is listed ahead of its ability, it's held back from the day it's out
		assert(
			PowerDefinition.get(powerId).IsOk or PowerDefinition.getIfUpcoming(powerId),
			`"{listing.Id}" lists "{powerId}", which is no power`
		)
		assert(ListingsByPowerId[powerId] == nil, `the power "{powerId}" is listed twice`)
		ListingsByPowerId[powerId] = listing
	end
end

-- everything the game holds back, none in a game where everything is anybody's
Module.list = function(): { Listing }
	return LISTINGS
end

-- the listing that holds an item or a power back, nil for what's anybody's
Module.getOf = function(itemOrPowerId: string): Listing?
	return ListingsByItemId[itemOrPowerId] or ListingsByPowerId[itemOrPowerId]
end

-- what stands between a player + everything a listing hands over
Module.getListingAccess = function(listing: Listing): Access
	return AccessByListing[listing] or newAccess(listing)
end

-- what stands between a player + an item or a power
Module.getAccess = function(itemOrPowerId: string): Access
	local listing = Module.getOf(itemOrPowerId)
	return if listing then Module.getListingAccess(listing) else FREE
end

-- whether a lock is open to whoever has that
Module.getIfOpen = function(lock: Lock, owned: Owned): boolean
	if lock.Type == "Entitlement" then
		return owned.Entitlements ~= nil and table.find(owned.Entitlements, lock.Key) ~= nil
	end
	return owned.HasGroupPerk == true
end

-- whether an item or a power is theirs to put on: what's listed at a price by having been handed over, what's
-- behind a lock by what opens it. whatever isn't listed is anybody's
Module.getIfOwned = function(owned: Owned, itemOrPowerId: string): boolean
	local listing = Module.getOf(itemOrPowerId)
	if not listing then
		return true
	end
	local lock = listing.Lock
	if lock then
		return Module.getIfOpen(lock, owned)
	end
	return getIfHeld(if listing.PowerId then owned.PowerIds else owned.ItemIds, itemOrPowerId)
end

-- what a character holds by its slot, to be let stay there
Module.getKept = function(prior: Character): Kept
	local out: Kept = {
		PowerIds = {},
		ItemIds = {},
	}
	for _, power in prior.Powers do
		out.PowerIds[power.Id] = true
	end
	for _, identityKey: IdentityKey in IDENTITY_KEYS do
		local identity = prior.Identities[identityKey]
		if not identity then
			continue
		end
		local itemIds: { [string]: true } = {}
		for _, item in identity.Appearance.Items do
			itemIds[item.DefinitionId] = true
		end
		out.ItemIds[identityKey] = itemIds
	end
	return out
end

-- the listings of what a character wears + wields that aren't its player's, each once, in the order they're met.
-- what's kept isn't asked about: a piece stays on the identity that had it, a power on the character. the editor +
-- the server ask the same thing
Module.getUnowned = function(character: Character, owned: Owned, kept: Kept?): { Listing }
	local out: { Listing } = {}
	local function check(id: string, keptIds: { [string]: true }?)
		local listing = Module.getOf(id)
		if
			listing
			and not (keptIds and keptIds[id])
			and not Module.getIfOwned(owned, id)
			and not table.find(out, listing)
		then
			table.insert(out, listing)
		end
	end
	for _, power in character.Powers do
		check(power.Id, kept and kept.PowerIds)
	end
	for _, identityKey: IdentityKey in IDENTITY_KEYS do
		local identity = character.Identities[identityKey]
		if identity then
			for _, item in identity.Appearance.Items do
				check(item.DefinitionId, kept and kept.ItemIds[identityKey])
			end
		end
	end
	return out
end

return Module
