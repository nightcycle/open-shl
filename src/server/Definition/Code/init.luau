--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local CodeType = require("@game/ServerScriptService/Server/Type/Code")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type CodeCatalogue = CodeType.CodeCatalogue
type PlayerSave = SaveType.PlayerSave
export type CodeDefinition = CodeType.CodeDefinition
-- Constants
-- the codes of a game are its own, the catalogue of another game is never required. they're the server's: no place
-- holds one where a client could read it
local CATALOGUE: CodeCatalogue = GameDefinition.pick({
	shl1 = function(): CodeCatalogue
		error(`shl1 has no codes`)
	end,
	shl2 = function(): CodeCatalogue
		error(`shl2 has no codes`)
	end,
	shl3 = function(): CodeCatalogue
		return require("@self/SHL3")
	end,
})
assert(CodeType.CodeCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
-- Variables
-- References
-- Private Functions
-- a code is typed in by hand, on a phone as well: the keyboard adds a space behind it + a capital in front
local function getKey(text: string): string
	return string.lower(string.match(text, "^%s*(.-)%s*$") or "")
end
-- Class
local Module = {}

local Definitions: { [string]: CodeDefinition } = {}
do
	local ids: { [string]: true } = {}
	for _, definition in CATALOGUE.Definitions do
		local key = getKey(definition.Text)
		assert(key ~= "", `the code "{definition.Id}" has nothing to type`)
		assert(not Definitions[key], `"{definition.Text}" is the text of two codes`)
		assert(not ids[definition.Id], `two codes have the id "{definition.Id}"`)
		Definitions[key] = definition
		ids[definition.Id] = true
	end
end

-- the code a text stands for, whatever case it's in + whatever space is around it. the old place only took the
-- exact word
Module.find = function(text: string): CodeDefinition?
	return Definitions[getKey(text)]
end

-- the ids of the codes a save was paid for, as the list of that save. nil for a save that keeps none
Module.getRedeemedIds = function(save: PlayerSave): { string }?
	return CATALOGUE.getRedeemedIds(save)
end

Module.list = function(): { CodeDefinition }
	return CATALOGUE.Definitions
end

return Module
