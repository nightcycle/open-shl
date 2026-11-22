--!strict
-- Services
-- Packages
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type ClientDefinition = PropType.ClientDefinition
-- Constants
-- a game that has no props builds none
local NONE: { ClientDefinition } = table.freeze({})
-- which props are built is the game's own. the halves of another game's are never required, so none of them looks
-- for a prop this game doesn't have
local DEFINITIONS: { ClientDefinition } = GameDefinition.pick({
	shl1 = function(): { ClientDefinition }
		return NONE
	end,
	shl2 = function(): { ClientDefinition }
		return NONE
	end,
	shl3 = function(): { ClientDefinition }
		return require("@self/SHL3")
	end,
})
-- Variables
local DefinitionsById: { [string]: ClientDefinition } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, definition in DEFINITIONS do
	local id = definition.Prop.Id
	assert(DefinitionsById[id] == nil, `the client half of "{id}" is defined twice`)
	assert(PropDefinition.get(id).IsOk, `the client half of "{id}" is built for a prop the game doesn't list as built`)
	DefinitionsById[id] = definition
end
-- a prop without a half can't be handed out: a row moves up from the upcoming ones once both of its halves are in
for _, definition in PropDefinition.list() do
	assert(DefinitionsById[definition.Id] ~= nil, `"{definition.Id}" is listed as built + has no client half`)
end

-- an error for a prop the game doesn't list as built: every one that is has a half
Module.get = function(id: string): ClientDefinition
	local definition = DefinitionsById[id]
	assert(definition, `no client half of "{id}"`)
	return definition
end

return Module
