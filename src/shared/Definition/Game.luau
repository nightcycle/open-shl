--!strict
-- Services
-- Packages
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
-- Types
local GameType = require("@game/ReplicatedStorage/Shared/Type/Game")
export type GameId = GameType.GameId
export type Features = GameType.Features
export type Loaders<V> = GameType.Loaders<V>
export type Tuning<V> = GameType.Tuning<V>
-- Constants
-- every place is this code built for one game, which one is baked in the way its mode is
local ID: GameId = BUILD_CONFIG.GAME
assert(GameType.GameId(ID))
local FEATURES: { shl1: Features, shl2: Features, shl3: Features } = table.freeze({
	-- what it boots with so far, the rest goes on as each of them is built for it
	shl1 = table.freeze({
		-- its flats are scenery
		Residences = false,
		Furniture = false,
		Quests = false,
		Tutorial = false,
		Music = false,
		Uniforms = false,
		CustomServers = false,
		Teams = false,
		Jobs = false,
		Props = false,
		PrivateServerToggle = false,
		-- its face is one picture, there's nothing for an expression to swap
		Roleplay = false,
		-- it's one place
		ModeSelect = false,
		DayNight = true,
		-- its map marks none of them
		Fixtures = false,
		PlayerMode = true,
		Leaderstats = false,
	}),
	-- the game all of it was written for: what's on is what ran before there was a second one
	shl2 = table.freeze({
		Residences = true,
		Furniture = true,
		Quests = true,
		Tutorial = true,
		Music = true,
		Uniforms = true,
		CustomServers = true,
		Teams = false,
		Jobs = false,
		Props = false,
		PrivateServerToggle = false,
		Roleplay = true,
		ModeSelect = true,
		DayNight = true,
		Fixtures = true,
		PlayerMode = false,
		Leaderstats = false,
	}),
	-- what it boots with so far, the rest goes on as each of them is built for it
	shl3 = table.freeze({
		Residences = false,
		Furniture = false,
		Quests = false,
		Tutorial = false,
		Music = false,
		Uniforms = false,
		CustomServers = false,
		-- heroes + villains where a place has its players fight, + the jail a villain comes in at
		Teams = true,
		Jobs = false,
		-- what its pads hand out: the two that are built so far, the rest of them lie there
		Props = true,
		PrivateServerToggle = false,
		-- its faces have no expressions yet
		Roleplay = false,
		ModeSelect = true,
		-- its day is another clock's to run
		DayNight = false,
		Fixtures = true,
		PlayerMode = false,
		-- what a player has to spend was read off the list of players in its old place, + nowhere else
		Leaderstats = true,
	}),
})
-- Variables
-- References
-- Private Functions
-- the checker takes a field that's looked up by the id for anything at all, so the three are spelt out
local function get<V>(shl1: V, shl2: V, shl3: V): V
	if ID == "shl1" then
		return shl1
	elseif ID == "shl2" then
		return shl2
	elseif ID == "shl3" then
		return shl3
	end
	error(`no game "{ID}"`)
end
-- Class
-- the id is in from the start, as a field that's assigned afterwards the checker only knows it for a string
local Module = {
	ID = ID,
}

for id, features in FEATURES :: { [string]: Features } do
	assert(GameType.GameId(id))
	assert(GameType.Features(features))
end

-- what the game this place is built for runs
Module.FEATURES = get(FEATURES.shl1, FEATURES.shl2, FEATURES.shl3)

-- the entry of the game this place is built for. what the other games have is never required, so none of it runs +
-- nothing of theirs waits on a library this place doesn't mount. a game that's left out is a type error
Module.pick = function<V>(loaders: Loaders<V>): V
	-- a game there isn't is one the checker lets through
	assert(GameType.Loaders(loaders))
	local load = get(loaders.shl1, loaders.shl2, loaders.shl3)
	return load()
end

-- a value every game shares unless it has one of its own
Module.tune = function<V>(default: V, own: Tuning<V>): V
	-- every field is optional, so the checker lets a misspelt game through
	assert(GameType.Tuning(own))
	local value = get(own.shl1, own.shl2, own.shl3)
	return if value ~= nil then value else default
end

return Module
