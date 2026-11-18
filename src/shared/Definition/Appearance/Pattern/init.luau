--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type PatternDefinition = AppearanceType.PatternDefinition
-- Constants
-- a game that has none draws every texture group plain
local NONE: { PatternDefinition } = table.freeze({})
-- which images can be drawn over a color is the game's own, the patterns of another game are never required
local PATTERNS: { PatternDefinition } = GameDefinition.pick({
	shl1 = function(): { PatternDefinition }
		return NONE
	end,
	shl2 = function(): { PatternDefinition }
		return NONE
	end,
	shl3 = function(): { PatternDefinition }
		return require("@self/SHL3")
	end,
})
assert(Type.array(AppearanceType.PatternDefinition)(PATTERNS))
TableUtil.deepFreeze(PATTERNS)
-- Variables
local DefinitionsByKey: { [string]: PatternDefinition? } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, definition in PATTERNS do
	assert(definition.Key ~= "", `a pattern has no key`)
	assert(DefinitionsByKey[definition.Key] == nil, `duplicate pattern "{definition.Key}"`)
	DefinitionsByKey[definition.Key] = definition
end

-- in the order a picker lists them
Module.list = function(): { PatternDefinition }
	return PATTERNS
end

-- a save can be older than the patterns of its game, so a key that isn't there is something to draw nothing for
-- rather than to stop on
Module.get = function(key: string): Result<PatternDefinition, string>
	local definition = DefinitionsByKey[key]
	if definition then
		return Result.ok(definition)
	end
	return Result.err(`no pattern "{key}"`)
end

return Module
