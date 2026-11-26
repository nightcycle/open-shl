--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
export type Kept = AccessDefinition.Kept
export type Lock = AccessDefinition.Lock
export type Owned = AccessDefinition.Owned
-- Constants
-- what one rented thing costs to keep for good in a slot, whatever it cost to rent
local KEEP_PRICE = 100
-- what a fee is paid in
local CURRENCY: PseudoEnum.Currency = PseudoEnum.Currency.Credits
-- an attribute holds no list: the ids a client is told of are one text, none of them has this in it
local SEPARATOR = ","
-- the order a character is gone through in
local IDENTITY_KEYS: { IdentityKey } = table.freeze({ "Main" :: IdentityKey, "Secret" })
-- Variables
-- References
-- Private Functions
local function getIfHeld(character: Character, id: string): boolean
	for _, power in character.Powers do
		if power.Id == id then
			return true
		end
	end
	for _, identityKey: IdentityKey in IDENTITY_KEYS do
		local identity = character.Identities[identityKey]
		if not identity then
			continue
		end
		for _, item in identity.Appearance.Items do
			if item.DefinitionId == id then
				return true
			end
		end
	end
	return false
end
-- Class
-- what's behind a pass can be had for a fee without it: for a visit by what its lock asks, for good in a slot by what
-- keeping asks on top of that. a fee is by the lock, things that share one are rented + kept as one. both ends ask
-- these: the editor for what a button is going to cost, the server for what it takes
local Module = {}

Module.KEEP_PRICE = KEEP_PRICE
Module.CURRENCY = CURRENCY

-- the locks a list of ids is behind, each once, in the order they're met. the limbs of a suit are one thing
Module.getThings = function(ids: { string }): { Lock }
	local out: { Lock } = {}
	local isMet: { [string]: true } = {}
	for _, id in ids do
		local listing = AccessDefinition.getOf(id)
		local lock = if listing then listing.Lock else nil
		if lock and not isMet[lock.Id] then
			isMet[lock.Id] = true
			table.insert(out, lock)
		end
	end
	return out
end

-- what a visit with all of them costs. something that's held back another way than by a pass isn't had for a fee
Module.getRentPrice = function(ids: { string }): Result<number, string>
	local price = 0
	local isMet: { [string]: true } = {}
	for _, id in ids do
		local listing = AccessDefinition.getOf(id)
		if not listing then
			continue
		end
		local lock = listing.Lock
		local rentPrice = if lock and lock.Type == "Entitlement" then lock.RentPrice else nil
		if not lock or not rentPrice then
			return Result.err(`"{listing.Name}" can't be rented`)
		end
		if not isMet[lock.Id] then
			isMet[lock.Id] = true
			price += rentPrice
		end
	end
	return Result.ok(price)
end

-- which of the ids a character has on, in the order of the ids
Module.listHeld = function(character: Character, ids: { string }): { string }
	local out: { string } = {}
	for _, id in ids do
		if getIfHeld(character, id) then
			table.insert(out, id)
		end
	end
	return out
end

-- what it costs to keep what a character still has on of what was rented. what it took off since isn't paid for
Module.getKeepPrice = function(rentedIds: { string }, character: Character): number
	return KEEP_PRICE * #Module.getThings(Module.listHeld(character, rentedIds))
end

-- what a slot holds for good, to be let stay there. whatever it only has on for the visit is no part of that: the
-- ids of it are handed in for the slot that's played, which is the only one that has any
Module.getKept = function(prior: Character, rentedIds: { string }?): Kept
	local out = AccessDefinition.getKept(prior)
	if rentedIds then
		for _, id in rentedIds do
			out.PowerIds[id] = nil
			for _, itemIds in out.ItemIds do
				itemIds[id] = nil
			end
		end
	end
	return out
end

-- the ids of what a character wears + wields that's neither its player's nor its slot's to keep, each once, in the
-- order they're met: what a fee is due for, or what it's turned down for
Module.listNeeded = function(character: Character, owned: Owned, kept: Kept): { string }
	local out: { string } = {}
	local function check(id: string, keptIds: { [string]: true }?)
		if not (keptIds and keptIds[id]) and not AccessDefinition.getIfOwned(owned, id) and not table.find(out, id) then
			table.insert(out, id)
		end
	end
	for _, power in character.Powers do
		check(power.Id, kept.PowerIds)
	end
	for _, identityKey: IdentityKey in IDENTITY_KEYS do
		local identity = character.Identities[identityKey]
		if identity then
			for _, item in identity.Appearance.Items do
				check(item.DefinitionId, kept.ItemIds[identityKey])
			end
		end
	end
	return out
end

-- the ids as the one text a client is told them by + back
Module.toAttribute = function(ids: { string }): string
	return table.concat(ids, SEPARATOR)
end

Module.fromAttribute = function(text: string): { string }
	return if text == "" then {} else string.split(text, SEPARATOR)
end

return table.freeze(Module)
