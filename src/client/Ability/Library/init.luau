--!strict
-- Services
-- Packages
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientDefinition = AbilityType.ClientDefinition
-- Constants
-- which abilities are built is the game's own. the halves of another game's are never required, so none of them
-- looks for a power this game doesn't have
local DEFINITIONS: { ClientDefinition } = GameDefinition.pick({
	shl1 = function(): { ClientDefinition }
		error(`shl1 has no abilities yet`)
	end,
	shl2 = function(): { ClientDefinition }
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Set/SHL2")
	end,
	shl3 = function(): { ClientDefinition }
		error(`shl3 has no abilities yet`)
	end,
})
-- Variables
local DefinitionsById: { [string]: ClientDefinition } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, definition in DEFINITIONS do
	local id = definition.Layout.Id
	assert(DefinitionsById[id] == nil, `the client half of "{id}" is defined twice`)
	-- not every half looks its power up itself, + one that's built without a power is never handed out
	assert(PowerDefinition.get(id).IsOk, `the client half of "{id}" is built for a power the game doesn't have`)
	DefinitionsById[id] = definition
end

-- nil for an ability that isn't built yet
Module.get = function(id: string): ClientDefinition?
	return DefinitionsById[id]
end

return Module
