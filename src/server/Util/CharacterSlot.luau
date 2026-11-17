--!strict
-- Services
local HttpService = game:GetService("HttpService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local LegacyDataMigration = require("@game/ServerScriptService/Server/Util/LegacyDataMigration")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
-- Constants
local STARTER_SUIT_COUNT = 10
-- Variables
-- References
-- what a new player starts out with, each json file of the folder is a module named Suit + its slot
local StarterSuits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/starter-suits") :: Folder
-- Private Functions
-- every slot of every player gets its own, a starter suit comes with one that's baked in + shared by everybody
local function newId(): string
	return HttpService:GenerateGUID(false)
end
-- Class
local Util = {}

function Util.newBlank(): Character
	return FreezeUtil.delta(CharacterConstructor.new(), function(t: Character): Character
		t.Id = newId()
		return t
	end)
end

-- the slots of a new player, a suit that fails to convert is left out
function Util.newStarters(): { Character }
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
		table.insert(
			out,
			FreezeUtil.delta(characterRes.Value, function(t: Character): Character
				t.Id = newId()
				return t
			end)
		)
	end
	-- a player can't be left without a character to wear
	if #out == 0 then
		table.insert(out, Util.newBlank())
	end
	table.freeze(out)
	return out
end

return Util
