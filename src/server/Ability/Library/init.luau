--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerDefinition = AbilityType.ServerDefinition
-- Constants
local DEFINITIONS: { ServerDefinition } = {
	require("@self/BasicMelee/Sword"),
	require("@self/Ranged/FireHand"),
	require("@self/Special/ForceField"),
	require("@self/Transportation/Flight"),
}
-- Variables
local DefinitionsById: { [string]: ServerDefinition } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, definition in DEFINITIONS do
	local id = definition.Layout.Id
	assert(DefinitionsById[id] == nil, `the server half of "{id}" is defined twice`)
	DefinitionsById[id] = definition
end

-- nil for an ability that isn't built yet
Module.get = function(id: string): ServerDefinition?
	return DefinitionsById[id]
end

return Module
