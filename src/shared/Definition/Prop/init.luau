--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
export type PropDefinition = PropType.PropDefinition
export type UseRule = PropType.UseRule
type PropCatalogue = PropType.PropCatalogue
-- Constants
-- lower case words with dashes between them, the way a power is spelt after its group
local ID_PATTERN = "^%l[%l%d%-]*$"
local TOOL_ID_ATTRIBUTE = "PropId"
-- a game that has none hands none out
local NONE: PropCatalogue = table.freeze({ Definitions = table.freeze({}) })
-- what there is to hold is the game's own, the props of another game are never required
local CATALOGUE: PropCatalogue = GameDefinition.pick({
	shl1 = function(): PropCatalogue
		return NONE
	end,
	shl2 = function(): PropCatalogue
		return NONE
	end,
	shl3 = function(): PropCatalogue
		return require("@self/SHL3")
	end,
})
assert(PropType.PropCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local DEFINITIONS = CATALOGUE.Definitions
local UPCOMING: { PropDefinition } = CATALOGUE.Upcoming or table.freeze({})
local RETIRED: { string } = CATALOGUE.Retired or table.freeze({})
-- Variables
local DefinitionsById: { [string]: PropDefinition? } = {}
-- by its id + by its name: a pad says either
local DefinitionsByName: { [string]: PropDefinition? } = {}
local UpcomingNames: { [string]: true } = {}
local RetiredNames: { [string]: true } = {}
-- References
-- Private Functions
-- Class
local Module = {}

do
	-- one list of names for all of them: a pad that names something has to mean one thing
	local names: { [string]: true } = {}
	local function claim(name: string)
		assert(name ~= "" and not names[name], `"{name}" is the name of two props`)
		names[name] = true
	end
	for _, definition in DEFINITIONS do
		assert(definition.Id:match(ID_PATTERN) ~= nil, `bad prop id "{definition.Id}"`)
		claim(definition.Id)
		if definition.Name ~= definition.Id then
			claim(definition.Name)
		end
		DefinitionsById[definition.Id] = definition
		DefinitionsByName[definition.Id] = definition
		DefinitionsByName[definition.Name] = definition
	end
	-- an upcoming prop is held to what every row is, so all it takes once its halves are there is moving the row
	for _, definition in UPCOMING do
		assert(definition.Id:match(ID_PATTERN) ~= nil, `bad prop id "{definition.Id}"`)
		claim(definition.Id)
		UpcomingNames[definition.Id] = true
		if definition.Name ~= definition.Id then
			claim(definition.Name)
			UpcomingNames[definition.Name] = true
		end
	end
	for _, name in RETIRED do
		claim(name)
		RetiredNames[name] = true
	end
end

-- what the tool of a prop says it is
Module.TOOL_ID_ATTRIBUTE = TOOL_ID_ATTRIBUTE

Module.get = function(id: string): Result<PropDefinition, string>
	local definition = DefinitionsById[id]
	if definition then
		return Result.ok(definition)
	end
	return Result.err(`no prop "{id}"`)
end

-- the prop a pad means, by its id or by its name. nil for one that isn't built, whatever else it is
Module.find = function(name: string): PropDefinition?
	return DefinitionsByName[name]
end

-- a pad that names one of these is left where it is, nobody is handed anything
Module.getIfUpcoming = function(name: string): boolean
	return UpcomingNames[name] == true
end

-- a pad that names one of these is taken off the map
Module.getIfRetired = function(name: string): boolean
	return RetiredNames[name] == true
end

Module.list = function(): { PropDefinition }
	return DEFINITIONS
end

return Module
