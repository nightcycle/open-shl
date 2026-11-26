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
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
export type EmoteId = RoleplayType.EmoteId
export type EmoteDefinition = RoleplayType.EmoteDefinition
export type PoseDefinition = RoleplayType.PoseDefinition
type EmoteCatalogue = RoleplayType.EmoteCatalogue
-- Constants
-- what there is to act out is the game's own, the rows of another game are never required. the arms of whoever is
-- cuffed come with them, so a game without rows can't be asked for either
local CATALOGUE: EmoteCatalogue = GameDefinition.pick({
	shl1 = function(): EmoteCatalogue
		error(`shl1 has no emotes yet`)
	end,
	shl2 = function(): EmoteCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): EmoteCatalogue
		return require("@self/SHL3")
	end,
})
assert(RoleplayType.EmoteCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local DEFINITIONS = CATALOGUE.Definitions
local HANDCUFFS = CATALOGUE.Handcuffs
local MASK: PoseDefinition? = CATALOGUE.Mask
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.HANDCUFFS = HANDCUFFS
-- nil in a game whose heroes have no gesture for their mask
Module.MASK = MASK

Module.get = function(id: string): Result<EmoteDefinition, string>
	for _, definition in DEFINITIONS do
		if definition.Id == id then
			return Result.ok(definition)
		end
	end
	return Result.err(`no emote "{id}"`)
end

Module.list = function(): { EmoteDefinition }
	return DEFINITIONS
end

return Module
