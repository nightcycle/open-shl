--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type FaceSlot = AppearanceType.FaceSlot
export type ExpressionId = RoleplayType.ExpressionId
export type ExpressionDefinition = RoleplayType.ExpressionDefinition
type ExpressionFace = RoleplayType.ExpressionFace
-- Constants
-- the faces a player can pull are the game's own, the rows of another game are never required
local FACES: { ExpressionFace } = GameDefinition.pick({
	shl1 = function(): { ExpressionFace }
		return require("@self/SHL1")
	end,
	shl2 = function(): { ExpressionFace }
		return require("@self/SHL2")
	end,
	shl3 = function(): { ExpressionFace }
		return require("@self/SHL3")
	end,
})
TableUtil.deepFreeze(FACES)
-- Variables
local Definitions: { ExpressionDefinition } = {}
-- References
-- Private Functions
local function getFaceId(slot: FaceSlot, key: string): string
	local id = ItemAppearanceDefinition.getFaceId(slot, key)
	assert(ItemAppearanceDefinition.get(id).IsOk, `bad face item "{id}"`)
	return id
end

local function newDefinition(face: ExpressionFace): ExpressionDefinition
	local out: ExpressionDefinition = {
		Id = face.Id,
		Name = face.Name,
		DefinitionIds = {
			Eyebrows = getFaceId("Eyebrows", face.Eyebrows),
			Eyes = getFaceId("Eyes", face.Eyes),
			Mouth = getFaceId("Mouth", face.Mouth),
		},
	}
	TableUtil.deepFreeze(out)
	assert(RoleplayType.ExpressionDefinition(out))
	return out
end

-- Class
local Module = {}

for _, FACE in FACES do
	assert(RoleplayType.ExpressionFace(FACE))
	table.insert(Definitions, newDefinition(FACE))
end
table.freeze(Definitions)

Module.get = function(id: string): Result<ExpressionDefinition, string>
	for _, definition in Definitions do
		if definition.Id == id then
			return Result.ok(definition)
		end
	end
	return Result.err(`no expression "{id}"`)
end

Module.list = function(): { ExpressionDefinition }
	return Definitions
end

return Module
