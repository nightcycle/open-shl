--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientDefinition = AbilityType.ClientDefinition
-- Constants
local DEFINITIONS: { ClientDefinition } = {
	require("@self/BasicMelee/Sword"),
	require("@self/Ranged/FireHand"),
	require("@self/Special/ForceField"),
	require("@self/Transportation/Flight"),
}
-- Variables
local DefinitionsById: { [string]: ClientDefinition } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, definition in DEFINITIONS do
	local id = definition.Layout.Id
	assert(DefinitionsById[id] == nil, `the client half of "{id}" is defined twice`)
	DefinitionsById[id] = definition
end

-- nil for an ability that isn't built yet
Module.get = function(id: string): ClientDefinition?
	return DefinitionsById[id]
end

return Module
