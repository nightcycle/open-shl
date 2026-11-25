--!strict
-- Services
-- Packages
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Character = CharacterType.Character
type Owned = EconomyType.Owned
-- Constants
-- what the old place charged for each, as its players paid it: the stored cost times 1.675, up to the next hundred
local PRICES: { [string]: number } = table.freeze({
	["suits_assassin-suit"] = 13_000,
	["suits_cosmic-suit"] = 39_700,
	["suits_covert-suit"] = 7_100,
	["suits_espionage-suit"] = 7_100,
	["suits_heavy-suit"] = 0,
	["suits_magician-suit"] = 7_100,
	["suits_psycho-suit"] = 13_700,
	["suits_twilight-suit"] = 7_100,
	["shirts_jersey"] = 0,
	["shirts_sports-jacket"] = 0,
	["pants_short-shorts"] = 0,
	["accessories_knee-pads"] = 1_400,
	["accessories_rocket-boosters"] = 1_400,
	["accessories_shoulder-pads"] = 1_400,
	["accessories_shoulder-turrets"] = 12_700,
	["accessories_wrist-lasers"] = 7_200,
	["emblems_box-emblem"] = 1_400,
	["emblems_lightning-emblem"] = 12_200,
	["emblems_octagon-emblem"] = 1_400,
	["emblems_shield-emblem"] = 6_300,
	["emblems_trispoke-emblem"] = 6_800,
	["emblems_wing-emblem"] = 12_200,
	["capes_jetpack"] = 1_400,
	["capes_wings"] = 6_100,
	["hair_animazinghair"] = 1_300,
	["hair_bob-hair"] = 1_300,
	["hair_crazy-hair"] = 1_400,
	["hair_lovely-locks-hair"] = 1_200,
	["hair_manga-hero-hair"] = 1_500,
	["hair_mohawk-hair"] = 1_400,
	["hair_politician-hair"] = 1_300,
	["hair_princeton-hair"] = 1_300,
	["hair_roblohunk-hair"] = 1_400,
	["hair_scene-hair"] = 1_200,
	["hair_shaggy-hair"] = 1_400,
	["hair_spiked-hair"] = 1_300,
	["hair_straight-hair"] = 1_200,
	["hair_stylish-hair"] = 1_300,
	["hair_swoosh-hair"] = 1_400,
	["hair_ultraflash-hair"] = 1_300,
	["hair_wavy-hair"] = 1_500,
	["hats_backwards-cap"] = 1_500,
	["hats_cap"] = 1_400,
	["hats_headphones"] = 1_300,
	["hats_side-cap"] = 1_200,
	["glasses_hipster-glasses"] = 1_400,
	["glasses_shades"] = 1_100,
	["eyes_brave"] = 5_500,
	["eyes_normal"] = 1_300,
	["eyes_scared"] = 1_200,
	["eyes_worried"] = 1_100,
	["mouths_monster-smile"] = 1_300,
	["attacks_bo-staff"] = 1_100,
	["attacks_sword"] = 1_300,
	["attacks_hammer"] = 1_400,
	["attacks_fire-ray"] = 5_500,
	["attacks_freeze-ray"] = 5_600,
	["attacks_lightning"] = 12_700,
	["effects_mind-reading"] = 5_600,
	["effects_teleport"] = 6_000,
	["effects_x-ray-vision"] = 6_800,
	["effects_force-field"] = 13_000,
	["effects_invisibility"] = 52_800,
})
-- the whole catalogue came to this
local TOTAL = 319_500
local HAIR_ID = "cosmetics_hair_mohawk-hair"
local HAT_ID = "clothing_hats_cap"
local SUIT_TORSO_ID = "costume_suit-torso_cosmic-suit"
local SUIT_ARM_ID = "costume_suit-left-arm_cosmic-suit"
local STARTER_ID = "costume_suit-torso_aerial-suit"
local POWER_ID = "special_invisibility"
local STARTER_POWER_ID = "transportation_flight"
-- Variables
-- References
-- Private Functions
-- a character that wields + wears what it's told to, + nothing else
local function newCharacter(powerIds: { string }, mainIds: { string }, secretIds: { string }): Character
	return FreezeUtil.delta(CharacterConstructor.new(), function(t: Character): Character
		for _, powerId in powerIds do
			table.insert(t.Powers, { Id = powerId })
		end
		local secret = t.Identities.Secret
		assert(secret, `a character of this game has its secret identity`)
		for _, itemId in mainIds do
			table.insert(t.Identities.Main.Appearance.Items, ItemConstructor.new(itemId))
		end
		for _, itemId in secretIds do
			table.insert(secret.Appearance.Items, ItemConstructor.new(itemId))
		end
		return t
	end)
end

local function getIds(listings: { EconomyType.Listing }): string
	local ids: { string } = {}
	for _, listing in listings do
		table.insert(ids, listing.Id)
	end
	return table.concat(ids, ", ")
end
-- Class
return {
	-- every listing costs what the old place charged for it
	Prices = SpecUtil.newScenario(function()
		local total, count = 0, 0
		for _, listing in AccessDefinition.list() do
			local price = PRICES[listing.Id]
			assert(price ~= nil, `"{listing.Id}" is listed, the old place never sold it`)
			local access = AccessDefinition.getListingAccess(listing)
			assert(access.Type == "Price", `"{listing.Id}" isn't sold`)
			assert(access.Currency == "Credits", `"{listing.Id}" is sold for {access.Currency}`)
			assert(access.Amount == price, `"{listing.Id}" costs {access.Amount}, it was {price}`)
			total += access.Amount
			count += 1
		end
		for id in PRICES do
			count -= 1
			assert(count >= 0, `"{id}" or another one the old place sold isn't listed`)
		end
		assert(total == TOTAL, `the catalogue comes to {total}`)
	end),

	-- an id asks what its listing asks, whichever of a suit's pieces it is. what a new player starts out with asks
	-- nothing
	Access = SpecUtil.newScenario(function()
		local torso, arm = AccessDefinition.getOf(SUIT_TORSO_ID), AccessDefinition.getOf(SUIT_ARM_ID)
		assert(torso ~= nil and torso == arm, `the pieces of a suit aren't one listing`)
		assert(torso.ItemIds and #torso.ItemIds == 6, `a suit doesn't hand over six pieces`)
		local access = AccessDefinition.getAccess(SUIT_ARM_ID)
		assert(access.Type == "Price" and access.Amount == PRICES[torso.Id], `a piece of a suit doesn't cost the suit`)
		local powerAccess = AccessDefinition.getAccess(POWER_ID)
		assert(powerAccess.Type == "Price" and powerAccess.Amount == 52_800, `invisibility isn't 52,800`)
		assert(AccessDefinition.getAccess(STARTER_ID).Type == "Free", `a starter suit isn't free`)
		assert(AccessDefinition.getAccess(STARTER_POWER_ID).Type == "Free", `a starter power isn't free`)
	end),

	-- what was handed over is its player's, piece by piece. nobody's passes buy a thing
	Owned = SpecUtil.newScenario(function()
		local nothing: Owned = { ItemIds = {}, PowerIds = {} }
		local some: Owned = { ItemIds = { HAIR_ID, SUIT_ARM_ID }, PowerIds = { POWER_ID } }
		local passes: Owned = {
			ItemIds = {},
			PowerIds = {},
			Entitlements = { "ExtraPowers" :: EconomyType.EntitlementKey },
			HasGroupPerk = true,
		}
		for _, id in { HAIR_ID, HAT_ID, SUIT_TORSO_ID, SUIT_ARM_ID, POWER_ID } do
			assert(not AccessDefinition.getIfOwned(nothing, id), `"{id}" is a new player's`)
			assert(not AccessDefinition.getIfOwned(passes, id), `"{id}" is had for a pass`)
		end
		for _, id in { STARTER_ID, STARTER_POWER_ID } do
			assert(AccessDefinition.getIfOwned(nothing, id), `the starter "{id}" isn't a new player's`)
		end
		assert(AccessDefinition.getIfOwned(some, HAIR_ID), `a hair that was bought isn't owned`)
		assert(AccessDefinition.getIfOwned(some, SUIT_ARM_ID), `a piece that was handed over isn't owned`)
		assert(not AccessDefinition.getIfOwned(some, SUIT_TORSO_ID), `a piece that wasn't handed over is owned`)
		assert(AccessDefinition.getIfOwned(some, POWER_ID), `a power that was bought isn't owned`)
		-- an item is never had by the id of a power or the other way around
		assert(
			not AccessDefinition.getIfOwned({ ItemIds = { POWER_ID }, PowerIds = { HAIR_ID } }, POWER_ID),
			`a power is owned as an item`
		)
	end),

	-- a character is held to what its player has: each listing it's short of comes back once, what it started with
	-- or bought doesn't
	Unowned = SpecUtil.newScenario(function()
		local nothing: Owned = { ItemIds = {}, PowerIds = {} }
		local starter = newCharacter({ STARTER_POWER_ID }, { STARTER_ID }, {})
		assert(#AccessDefinition.getUnowned(starter, nothing) == 0, `a character of starters is short of something`)
		local character = newCharacter(
			{ STARTER_POWER_ID, POWER_ID },
			{ STARTER_ID, SUIT_ARM_ID, SUIT_TORSO_ID, HAIR_ID },
			{ HAIR_ID, HAT_ID }
		)
		local unowned = AccessDefinition.getUnowned(character, nothing)
		assert(
			getIds(unowned) == "effects_invisibility, suits_cosmic-suit, hair_mohawk-hair, hats_cap",
			`the character of a new player is short of: {getIds(unowned)}`
		)
		local some: Owned = { ItemIds = { HAIR_ID, SUIT_ARM_ID, SUIT_TORSO_ID }, PowerIds = { POWER_ID } }
		assert(getIds(AccessDefinition.getUnowned(character, some)) == "hats_cap", `what was bought is still missed`)
	end),

	-- what a slot held stays where it was, owned or not: a piece on the identity that wore it, a power on the
	-- character. it isn't theirs to put anywhere else, + once it's off it has to be bought to go back on
	Kept = SpecUtil.newScenario(function()
		local nothing: Owned = { ItemIds = {}, PowerIds = {} }
		-- what a pad does: a cap on the everyday identity that nobody paid for
		local prior = newCharacter({ POWER_ID }, { STARTER_ID }, { HAT_ID })
		local kept = AccessDefinition.getKept(prior)
		assert(#AccessDefinition.getUnowned(prior, nothing, kept) == 0, `a slot can't keep what it holds`)
		assert(
			getIds(AccessDefinition.getUnowned(prior, nothing)) == "effects_invisibility, hats_cap",
			`what nobody kept went through`
		)
		local bare = newCharacter({}, { STARTER_ID }, {})
		assert(#AccessDefinition.getUnowned(bare, nothing, kept) == 0, `a slot can't take off what it holds`)
		-- back on after a save without it: what's kept is read off the save as it is by then
		assert(
			getIds(AccessDefinition.getUnowned(prior, nothing, AccessDefinition.getKept(bare)))
				== "effects_invisibility, hats_cap",
			`what was taken off went back on unpaid`
		)
		local moved = newCharacter({ POWER_ID }, { STARTER_ID, HAT_ID }, {})
		assert(
			getIds(AccessDefinition.getUnowned(moved, nothing, kept)) == "hats_cap",
			`a piece one identity kept went on the other unpaid`
		)
		local more = newCharacter({ POWER_ID }, { STARTER_ID }, { HAT_ID, HAIR_ID })
		assert(
			getIds(AccessDefinition.getUnowned(more, nothing, kept)) == "hair_mohawk-hair",
			`what's kept let something else through`
		)
	end),
}
