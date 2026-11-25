--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
type Option<V> = TypeUnionLib.Option<V>
type Result<V, E> = TypeUnionLib.Result<V, E>
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
export type PowerGroup = PowerType.PowerGroup
export type PowerDefinition = PowerType.PowerDefinition
export type PowerSlot = PowerType.PowerSlot
type IdentityKey = CharacterType.IdentityKey
type PowerCatalogue = PowerType.PowerCatalogue
-- Constants
local ID_DELIMITER = "_"
local TOOL_ID_ATTRIBUTE = "PowerId"
-- what's on offer + how many of them a character carries is the game's own, the powers of another game are never
-- required
local CATALOGUE: PowerCatalogue = GameDefinition.pick({
	shl1 = function(): PowerCatalogue
		return require("@self/SHL1")
	end,
	shl2 = function(): PowerCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): PowerCatalogue
		return require("@self/SHL3")
	end,
})
assert(PowerType.PowerCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local GROUPS = CATALOGUE.Groups
local DEFINITIONS = CATALOGUE.Definitions
local UPCOMING: { PowerDefinition } = CATALOGUE.Upcoming or table.freeze({})
local SLOTS: { PowerSlot } = CATALOGUE.Slots or table.freeze({})
local DEFAULT_LIMIT = CATALOGUE.DefaultLimit
local PASS_LIMIT = CATALOGUE.PassLimit
local PASS_ENTITLEMENT = CATALOGUE.PassEntitlement
local IDENTITY_KEY: IdentityKey? = CATALOGUE.IdentityKey
-- Variables
local DefinitionsById: { [string]: PowerDefinition? } = {}
local DefinitionsByGroup: { [PowerGroup]: { PowerDefinition } } = {}
-- the slots of the game, each down to the powers of it that are offered. none in a game without
local Slots: { PowerSlot } = {}
local SlotsByPowerId: { [string]: PowerSlot? } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, group: PowerGroup in GROUPS do
	DefinitionsByGroup[group] = {}
end
for _, definition in DEFINITIONS do
	assert(PowerType.PowerDefinition(definition))
	local keys = definition.Id:split(ID_DELIMITER)
	assert(#keys == 2 and keys[1] == definition.Group and keys[2] ~= "", `bad power id "{definition.Id}"`)
	assert(DefinitionsById[definition.Id] == nil, `duplicate power id "{definition.Id}"`)
	DefinitionsById[definition.Id] = definition
	table.insert(DefinitionsByGroup[definition.Group], definition)
end
for _, group: PowerGroup in GROUPS do
	table.freeze(DefinitionsByGroup[group])
end
do
	-- an upcoming power is held to what every row is, so all it takes once its ability is there is moving the row. until
	-- then no id of theirs is answered for: it isn't listed, picked, saved or handed out
	local upcomingIds: { [string]: true } = {}
	for _, definition in UPCOMING do
		local keys = definition.Id:split(ID_DELIMITER)
		assert(#keys == 2 and keys[1] == definition.Group and keys[2] ~= "", `bad power id "{definition.Id}"`)
		assert(table.find(GROUPS, definition.Group) ~= nil, `"{definition.Id}" is of a group the game doesn't list`)
		assert(
			DefinitionsById[definition.Id] == nil and not upcomingIds[definition.Id],
			`duplicate power id "{definition.Id}"`
		)
		upcomingIds[definition.Id] = true
	end
	-- a slot lists every power that's ever going to be in it. what the game has of slots is those lists down to the
	-- powers that are offered, so a power moves into its slot with its row
	local slotKeys: { [string]: true } = {}
	local slottedIds: { [string]: true } = {}
	for _, slot in SLOTS do
		assert(not slotKeys[slot.Key], `duplicate power slot "{slot.Key}"`)
		slotKeys[slot.Key] = true
		local offered: PowerSlot = { Key = slot.Key, Caption = slot.Caption, PowerIds = {} }
		for _, id in slot.PowerIds do
			assert(
				DefinitionsById[id] ~= nil or upcomingIds[id],
				`the "{slot.Key}" slot lists "{id}", which is no power`
			)
			assert(not slottedIds[id], `"{id}" is in two slots`)
			slottedIds[id] = true
			if DefinitionsById[id] then
				table.insert(offered.PowerIds, id)
				SlotsByPowerId[id] = offered
			end
		end
		TableUtil.deepFreeze(offered)
		table.insert(Slots, offered)
	end
	if CATALOGUE.Slots then
		-- a power outside of every slot is one no character could hold
		for _, definition in DEFINITIONS do
			assert(SlotsByPowerId[definition.Id] ~= nil, `"{definition.Id}" is in no slot`)
		end
	end
	table.freeze(Slots)
end

Module.DEFAULT_LIMIT = DEFAULT_LIMIT
Module.PASS_LIMIT = PASS_LIMIT
-- what a player holds once they bought the pass that raises the limit, nil in a game where no pass does
Module.PASS_ENTITLEMENT = PASS_ENTITLEMENT
-- the one identity that carries the powers, nil in a game where every identity does
Module.IDENTITY_KEY = IDENTITY_KEY
Module.TOOL_ID_ATTRIBUTE = TOOL_ID_ATTRIBUTE

Module.get = function(id: string): Result<PowerDefinition, string>
	local definition = DefinitionsById[id]
	if definition then
		return Result.ok(definition)
	end
	return Result.err(`no power "{id}"`)
end

-- whether it's a power that's still on its way. nothing answers for one, what's written down of it ahead of its
-- ability is held to this
Module.getIfUpcoming = function(id: string): boolean
	for _, definition in UPCOMING do
		if definition.Id == id then
			return true
		end
	end
	return false
end

Module.list = function(group: PowerGroup?): { PowerDefinition }
	if group == nil then
		return DEFINITIONS
	end
	return DefinitionsByGroup[group]
end

-- in the order the editor lists them, each with the powers of it that are offered. none in a game whose characters
-- take any of its powers
Module.listSlots = function(): { PowerSlot }
	return Slots
end

-- nil for a power that's in none, which is every power of a game without slots
Module.getSlot = function(id: string): PowerSlot?
	return SlotsByPowerId[id]
end

-- whether an identity has the powers of its character to use
Module.getIfCarried = function(identityKey: IdentityKey): boolean
	return IDENTITY_KEY == nil or IDENTITY_KEY == identityKey
end

-- what's wrong with the powers a character holds, nil when nothing is: no more than the limit of its player, each a
-- power of the game, none twice + one of a slot at most. the editor + the server ask the same thing
Module.getLoadoutError = function(powerIds: { string }, limit: number): string?
	if #powerIds > limit then
		return `a character holds up to {limit} powers`
	end
	local isHeld: { [string]: true } = {}
	local isFilled: { [PowerSlot]: true } = {}
	for _, id in powerIds do
		if DefinitionsById[id] == nil then
			return `no power "{id}"`
		end
		if isHeld[id] then
			return `power "{id}" is held twice`
		end
		isHeld[id] = true
		local slot = SlotsByPowerId[id]
		if slot then
			if isFilled[slot] then
				return `a character holds one "{slot.Caption}" power`
			end
			isFilled[slot] = true
		end
	end
	return nil
end

Module.getColor = function(definition: PowerDefinition, color: Color3?): Option<Color3>
	local colorGroup = definition.ColorGroups.Primary
	if colorGroup == nil then
		return Option.none()
	end
	if color ~= nil then
		-- compared as hex, a color that went through a save or a remote may not be bit equal to its choice
		local hex = color:ToHex()
		for _, choice in colorGroup.Choices do
			if choice:ToHex() == hex then
				return Option.some(choice)
			end
		end
	end
	return Option.some(colorGroup.Default)
end

return Module
