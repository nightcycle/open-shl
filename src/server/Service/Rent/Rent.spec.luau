--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
-- only a game that rents has anything to hold this to: the ids below are of its lists
if not GameDefinition.FEATURES.Rent then
	return {} :: TestMap
end
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local Rule = require("@game/ServerScriptService/Server/Service/Rent/Rule")
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
-- Constants
-- one piece past the starters of each list, + one that's the group's
local HAIR = "cosmetics_hair_shaggy-hair"
local FACE = "cosmetics_face_head-9"
local HAT = "costume_hats_hat-13"
local EMBLEM = "costume_emblems_emblem-5"
local FREE_EMBLEM = "costume_emblems_emblem-2"
-- the limbs of suits past the starters, of one suit + of five
local TUX: { string } = table.freeze({
	"costume_suit-torso_tux",
	"costume_suit-left-arm_tux",
	"costume_suit-right-arm_tux",
	"costume_suit-left-leg_tux",
	"costume_suit-right-leg_tux",
})
local MIXED: { string } = table.freeze({
	"costume_suit-torso_tux",
	"costume_suit-left-arm_mercenary",
	"costume_suit-right-arm_mutant-2",
	"costume_suit-left-leg_mutant-3",
	"costume_suit-right-leg_mutant-5",
})
local CYBORG_TORSO = "costume_suit-torso_cyborg"
local CYBORG_LEFT_ARM = "costume_suit-left-arm_cyborg"
local KEEP_PRICE = 100
-- Variables
-- References
-- Private Functions
local function getPrice(ids: { string }): number?
	local priceRes = Rule.getRentPrice(ids)
	return if priceRes.IsOk then priceRes.Value else nil
end

local function wear(character: Character, identityKey: IdentityKey, ids: { string }): Character
	return FreezeUtil.delta(character, function(t: Character): Character
		local identity = t.Identities[identityKey]
		assert(identity, `the character has no "{identityKey}" identity`)
		for _, id in ids do
			table.insert(identity.Appearance.Items, ItemConstructor.new(id))
		end
		return t
	end)
end

local function getIfWorn(character: Character, identityKey: IdentityKey, id: string): boolean
	local identity = character.Identities[identityKey]
	assert(identity, `the character has no "{identityKey}" identity`)
	for _, item in identity.Appearance.Items do
		if item.DefinitionId == id then
			return true
		end
	end
	return false
end
-- Class
return {
	-- a fee is by the lock: 20 a row of the secret identity, 25 a row of the costume, a suit once however many limbs
	Prices = SpecUtil.newScenario(function()
		assert(getPrice({}) == 0, `nothing costs {tostring(getPrice({}))}`)
		assert(getPrice({ HAIR }) == 20, `a hair rents at {tostring(getPrice({ HAIR }))}`)
		assert(getPrice({ HAIR, FACE }) == 40, `a hair + a face rent at {tostring(getPrice({ HAIR, FACE }))}`)
		assert(getPrice({ HAT }) == 25, `a mask rents at {tostring(getPrice({ HAT }))}`)
		assert(getPrice(TUX) == 25, `the five limbs of a suit rent at {tostring(getPrice(TUX))}`)
		assert(getPrice(MIXED) == 25, `the limbs of five suits rent at {tostring(getPrice(MIXED))}`)
		assert(getPrice({ HAT, MIXED[1] }) == 50, `a mask + a limb rent at {tostring(getPrice({ HAT, MIXED[1] }))}`)
		assert(getPrice({ FREE_EMBLEM, CYBORG_TORSO }) == 0, `what's anybody's has a fee`)
		-- what the group opens is had for no fee, alone or among things that are
		assert(Rule.getRentPrice({ EMBLEM }).IsErr, `an emblem of the group has a fee`)
		assert(Rule.getRentPrice({ HAT, EMBLEM }).IsErr, `an emblem of the group was rented along with a mask`)
		assert(
			#Rule.getThings(TUX) == 1 and #Rule.getThings({ HAIR, FACE, HAT, TUX[1], TUX[2] }) == 4,
			`the things are off`
		)
	end),

	-- keeping is 100 a thing the character still has on, whatever it cost to rent
	Keep = SpecUtil.newScenario(function()
		local character = wear(wear(CharacterConstructor.new(), "Main", { HAIR, HAT }), "Main", TUX)
		local rentedIds = { HAIR, FACE, HAT, TUX[1], TUX[2], TUX[3], TUX[4], TUX[5] }
		assert(Rule.getKeepPrice(rentedIds, character) == 3 * KEEP_PRICE, `a hair, a mask + a suit aren't kept for 300`)
		assert(Rule.getKeepPrice({ FACE }, character) == 0, `what was taken off since is paid for`)
		assert(Rule.getKeepPrice({}, character) == 0, `nothing rented costs something to keep`)
	end),

	-- what ran out comes off, on every identity that has it on. a limb of a suit makes way for the first suit's
	Expire = SpecUtil.newScenario(function()
		local character =
			wear(CharacterConstructor.new(), "Main", { HAIR, HAT, FREE_EMBLEM, MIXED[1], MIXED[2], MIXED[3] })
		character = wear(character, "Secret", { HAIR })
		local expired = Rule.expire(character, { HAIR, HAT, MIXED[1], MIXED[2] })
		assert(table.isfrozen(expired), `what's left isn't frozen`)
		assert(
			not getIfWorn(expired, "Main", HAIR) and not getIfWorn(expired, "Secret", HAIR),
			`a rented hair is still on`
		)
		assert(not getIfWorn(expired, "Main", HAT), `a rented mask is still on`)
		assert(getIfWorn(expired, "Main", FREE_EMBLEM), `something that wasn't rented came off`)
		assert(getIfWorn(expired, "Main", MIXED[3]), `a limb that wasn't rented came off`)
		assert(
			getIfWorn(expired, "Main", CYBORG_TORSO) and getIfWorn(expired, "Main", CYBORG_LEFT_ARM),
			`a rented limb didn't make way for the first suit's`
		)
		assert(
			not getIfWorn(expired, "Main", MIXED[1]) and not getIfWorn(expired, "Main", MIXED[2]),
			`a rented limb is on`
		)
		local isCharacter, msg = CharacterType.Character(expired)
		assert(isCharacter, `what's left is no character: {tostring(msg)}`)
		-- with none of it on, the very character comes back
		assert(Rule.expire(character, { FACE }) == character, `a character with nothing rented on was made anew`)
	end),
}
