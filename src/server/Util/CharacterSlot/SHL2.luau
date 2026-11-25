--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local LegacyDataMigration = require("@game/ServerScriptService/Server/Util/LegacyDataMigration")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
type Result<V, E> = TypeUnionLib.Result<V, E>
-- Constants
local STARTER_SUIT_COUNT = 10
-- Variables
-- References
-- what a new player starts out with, each json file of the folder is a module named Suit + its slot
local StarterSuits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/starter-suits") :: Folder
-- Private Functions
-- the suits are kept the way the old game saved them, a suit that fails to convert is left out
local function list(): { Character }
	local out: { Character } = {}
	for index = 1, STARTER_SUIT_COUNT do
		local suitModule = StarterSuits:FindFirstChild(`Suit{index}`)
		if not suitModule or not suitModule:IsA("ModuleScript") then
			warn(`no starter suit {index}`)
			continue
		end
		-- required by instance, rojo turns each json into a module
		local characterRes = LegacyDataMigration.toCharacter(require(suitModule) :: unknown)
		if characterRes.IsErr then
			warn(`starter suit {index} err: {characterRes.Value}`)
			continue
		end
		table.insert(out, characterRes.Value)
	end
	return out
end
-- its starters are suits somebody made, there's no table to deal another from
local function roll(): Result<Character, string>
	return Result.err(`this game deals no characters`)
end
-- Class
return table.freeze({
	List = list,
	-- a slot that's added later is an empty one
	New = CharacterConstructor.new,
	Roll = roll,
})
