--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type FaceSlot = AppearanceType.FaceSlot
export type ExpressionId = RoleplayType.ExpressionId
export type ExpressionDefinition = RoleplayType.ExpressionDefinition
type Face = {
	Id: ExpressionId,
	Name: string,
	Eyebrows: string,
	Eyes: string,
	Mouth: string,
}
-- Constants
-- each slot holds the key of its face image
local FACES: { Face } = {
	{ Id = "Angry", Name = "Angry", Eyebrows = "angry", Eyes = "angry", Mouth = "angry" },
	{ Id = "Sinister", Name = "Sinister", Eyebrows = "angry", Eyes = "angry", Mouth = "happy" },
	{ Id = "Hateful", Name = "Hateful", Eyebrows = "angry", Eyes = "angry", Mouth = "neutral" },
	{ Id = "Skeptical", Name = "Skeptical", Eyebrows = "angry", Eyes = "angry", Mouth = "sad" },
	{ Id = "Cringing", Name = "Cringing", Eyebrows = "happy", Eyes = "neutral", Mouth = "angry" },
	{ Id = "Happy", Name = "Happy", Eyebrows = "happy", Eyes = "neutral", Mouth = "happy" },
	{ Id = "Nervous", Name = "Nervous", Eyebrows = "happy", Eyes = "neutral", Mouth = "neutral" },
	{ Id = "Guilty", Name = "Guilty", Eyebrows = "happy", Eyes = "neutral", Mouth = "sad" },
	{ Id = "Awestruck", Name = "Awestruck", Eyebrows = "happy", Eyes = "neutral", Mouth = "surprised" },
	{ Id = "Neutral", Name = "Neutral", Eyebrows = "neutral", Eyes = "neutral", Mouth = "neutral" },
	{ Id = "Hurt", Name = "Hurt", Eyebrows = "neutral", Eyes = "neutral", Mouth = "sad" },
	{ Id = "Depressed", Name = "Depressed", Eyebrows = "worried", Eyes = "sad", Mouth = "angry" },
	{ Id = "Weary", Name = "Weary", Eyebrows = "worried", Eyes = "sad", Mouth = "happy" },
	{ Id = "Sad", Name = "Sad", Eyebrows = "worried", Eyes = "sad", Mouth = "sad" },
	{ Id = "Traumatized", Name = "Traumatized", Eyebrows = "surprised", Eyes = "surprised", Mouth = "neutral" },
	{ Id = "Surprised", Name = "Surprised", Eyebrows = "surprised", Eyes = "surprised", Mouth = "surprised" },
}
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

local function newDefinition(face: Face): ExpressionDefinition
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
