--!strict
-- Services
local HttpService = game:GetService("HttpService")
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
-- where the characters a new player of a game starts out with come from
type Starters = {
	-- each the way it's kept, under an id everybody would share
	List: () -> { Character },
	-- what a slot that's added later holds, under an id everybody would share
	New: () -> Character,
}
-- Constants
-- what a new player starts out with is the game's own. the starters of another game are never required, so the data
-- they're made from doesn't have to be in the place
local STARTERS: Starters = GameDefinition.pick({
	shl1 = function(): Starters
		error(`shl1 has no starter characters yet`)
	end,
	shl2 = function(): Starters
		return require("@self/SHL2")
	end,
	shl3 = function(): Starters
		return require("@self/SHL3")
	end,
})
-- Variables
-- References
-- Private Functions
-- every slot of every player gets its own, a starter suit comes with one that's baked in + shared by everybody
local function newId(): string
	return HttpService:GenerateGUID(false)
end
-- Class
local Util = {}

function Util.newBlank(): Character
	return FreezeUtil.delta(STARTERS.New(), function(t: Character): Character
		t.Id = newId()
		return t
	end)
end

-- the slots of a new player
function Util.newStarters(): { Character }
	local out: { Character } = {}
	for _, starter in STARTERS.List() do
		table.insert(
			out,
			FreezeUtil.delta(starter, function(t: Character): Character
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
