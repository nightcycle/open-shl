--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local RentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Rent")
local WornUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Worn")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type TextureGroupKey = AppearanceType.TextureGroupKey
type Character = CharacterType.Character
type PlayerSave = SaveType.PlayerSave
-- Constants
-- the limbs of a suit: none of them is ever left bare, a hero doesn't come back without a chest
local LIMB_CATEGORIES: { string } = table.freeze({
	"suit-torso",
	"suit-left-arm",
	"suit-right-arm",
	"suit-left-leg",
	"suit-right-leg",
})
-- Variables
-- References
-- Private Functions
-- what a limb wears once the piece it rented ran out: the same limb of the first suit on the list, which is
-- anybody's. nil for anything that's simply taken off
local function getStandInId(definitionId: string): string?
	local indexRes = ItemAppearanceDefinition.getIndex(definitionId)
	if indexRes.IsErr or not table.find(LIMB_CATEGORIES, indexRes.Value.Category) then
		return nil
	end
	local first = ItemAppearanceDefinition.list(indexRes.Value.Group, indexRes.Value.Category)[1]
	return if first and first.IsStarter and first.Id ~= definitionId then first.Id else nil
end

-- the piece that takes the place of one that ran out, in the look that one was worn in: what was picked for a group
-- both have goes along, any other group starts out the way the game has a new piece start out beside what's worn
local function newStandIn(appearance: Appearance, item: Item, standInId: string): Item
	local standIn = WornUtil.newItem(appearance, standInId)
	local itemDefRes = ItemAppearanceDefinition.get(standInId)
	if itemDefRes.IsErr then
		return standIn
	end
	local itemDef = itemDefRes.Value
	return FreezeUtil.delta(standIn, function(t: Item): Item
		for _, key: TextureGroupKey in itemDef.TextureGroups do
			local group = item.TextureGroups[key]
			if group then
				t.TextureGroups[key] = group
			end
		end
		return t
	end)
end

-- a look without what ran out of it, the look itself when nothing of it did
local function expireAppearance(appearance: Appearance, isRented: { [string]: true }): Appearance
	local items: { Item } = {}
	local isChanged = false
	for _, item in appearance.Items do
		if not isRented[item.DefinitionId] then
			table.insert(items, item)
			continue
		end
		isChanged = true
		local standInId = getStandInId(item.DefinitionId)
		if standInId then
			table.insert(items, newStandIn(appearance, item, standInId))
		end
	end
	if not isChanged then
		return appearance
	end
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		t.Items = items
		return t
	end)
end
-- Class
-- what the fees come to + what running out does to a character. nothing in here knows of a player or a session: the
-- service holds a request to it, the session + the character service run a save through it wherever a visit ends
local Rule = {}

Rule.getThings = RentDefinition.getThings
Rule.getRentPrice = RentDefinition.getRentPrice
Rule.getKeepPrice = RentDefinition.getKeepPrice

-- the character without what was rented for it: a piece is taken off, on every identity that has it on, a power is
-- let go of, + a limb of a suit makes way for the same limb of the first suit. the rest of it stays as it is. the
-- very character comes back when it has none of that on
function Rule.expire(character: Character, rentedIds: { string }): Character
	if #RentDefinition.listHeld(character, rentedIds) == 0 then
		return character
	end
	local isRented: { [string]: true } = {}
	for _, id in rentedIds do
		isRented[id] = true
	end
	return FreezeUtil.delta(character, function(t: Character): Character
		local powers: { CharacterType.Power } = {}
		for _, power in t.Powers do
			if not isRented[power.Id] then
				table.insert(powers, power)
			end
		end
		t.Powers = powers
		for _, identity in t.Identities do
			if identity then
				for id in isRented do
					identity.PowerSkins[id] = nil
				end
				identity.Appearance = expireAppearance(identity.Appearance, isRented)
			end
		end
		return t
	end)
end

-- runs out what the save says is rented, on a save that's open for a write: whoever is played loses it + the list is
-- empty after. it's what keeps the list the played character's, so it goes ahead of every write that says who that
-- is. it can't yield
function Rule.expireSave(save: PlayerSave)
	local section = save.SHL1
	assert(section, `a save of this game has its section`)
	if #section.RentedItemIds == 0 then
		return
	end
	for index, character in save.Characters do
		if character.Id == save.ActiveCharacterId then
			save.Characters[index] = Rule.expire(character, section.RentedItemIds)
		end
	end
	section.RentedItemIds = {}
end

return table.freeze(Rule)
