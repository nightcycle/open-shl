--!strict
-- Services
local HttpService = game:GetService("HttpService")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type Owned = EconomyType.Owned
-- where the characters a new player of a game starts out with come from
type Starters = {
	-- each the way it's kept, under an id everybody would share
	List: () -> { Character },
	-- what a slot that's added later holds, under an id everybody would share. a game that deals its characters
	-- deals this one out of what the player has by then
	New: (owned: Owned?) -> Character,
	-- a character dealt anew out of what a player has, without an id. an error in a game that deals none
	Roll: (owned: Owned) -> Result<Character, string>,
}
-- Constants
-- what a new player starts out with is the game's own. the starters of another game are never required, so the data
-- they're made from doesn't have to be in the place
local STARTERS: Starters = GameDefinition.pick({
	shl1 = function(): Starters
		return require("@self/SHL1")
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

function Util.newBlank(owned: Owned?): Character
	return FreezeUtil.delta(STARTERS.New(owned), function(t: Character): Character
		t.Id = newId()
		return t
	end)
end

-- what an editor swaps its draft for when its player asks for somebody else. it comes without an id: it's nobody's
-- slot until a save makes it one
function Util.roll(owned: Owned): Result<Character, string>
	return STARTERS.Roll(owned)
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
