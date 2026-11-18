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
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
export type PowerGroup = PowerType.PowerGroup
export type PowerDefinition = PowerType.PowerDefinition
type PowerCatalogue = PowerType.PowerCatalogue
-- Constants
local ID_DELIMITER = "_"
local TOOL_ID_ATTRIBUTE = "PowerId"
-- what's on offer + how many of them a character carries is the game's own, the powers of another game are never
-- required
local CATALOGUE: PowerCatalogue = GameDefinition.pick({
	shl1 = function(): PowerCatalogue
		error(`shl1 has no powers yet`)
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
local DEFAULT_LIMIT = CATALOGUE.DefaultLimit
local PASS_LIMIT = CATALOGUE.PassLimit
local PASS_ENTITLEMENT = CATALOGUE.PassEntitlement
-- Variables
local DefinitionsById: { [string]: PowerDefinition? } = {}
local DefinitionsByGroup: { [PowerGroup]: { PowerDefinition } } = {}
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
end

Module.DEFAULT_LIMIT = DEFAULT_LIMIT
Module.PASS_LIMIT = PASS_LIMIT
-- what a player holds once they bought the pass that raises the limit
Module.PASS_ENTITLEMENT = PASS_ENTITLEMENT
Module.TOOL_ID_ATTRIBUTE = TOOL_ID_ATTRIBUTE

Module.get = function(id: string): Result<PowerDefinition, string>
	local definition = DefinitionsById[id]
	if definition then
		return Result.ok(definition)
	end
	return Result.err(`no power "{id}"`)
end

Module.list = function(group: PowerGroup?): { PowerDefinition }
	if group == nil then
		return DEFINITIONS
	end
	return DefinitionsByGroup[group]
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
