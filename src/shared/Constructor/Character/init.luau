--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local IdentityConstructor = require("@self/Identity")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type Character = CharacterType.Character
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.new = function(): Character
	local out: Character = {
		Id = "",
		Powers = {},
		Identities = {
			Main = IdentityConstructor.new(),
		},
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
