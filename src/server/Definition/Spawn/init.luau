--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
type Tag<I> = MapDefinition.Tag<I>
-- how an avatar comes into the world of a game. whatever a rule leaves out is left the way the map + the session
-- have it. how long it takes to come back is a setting of the place, the game is built with it
export type Rule = {
	-- what the spots an avatar comes in at wear, the engine picks one of them. without one they're whichever
	-- spawn locations the map has
	Tag: Tag<SpawnLocation>?,
	-- seconds an avatar keeps the force field its spot hands it, written onto every spot. nothing here is stopped
	-- by one. without it the spots keep what the map says
	ShieldDuration: number?,
	-- seconds of force field for an avatar that came in behind a menu, from the moment it's first let out of it: the
	-- one its spot handed it ran out where nobody could have hit it. without it such an avatar is let out bare
	EntryShieldDuration: number?,
	-- the identity an avatar comes back in, without one it's whoever it was when it went down
	IdentityKey: IdentityKey?,
}
-- Constants
local isRule = Type.intersection(
	Type.strictInterface({
		Tag = Type.optional(Type.strictInterface({
			Name = Type.string,
			ClassName = Type.literal("SpawnLocation"),
		})),
		ShieldDuration = Type.optional(Type.numberMin(0)),
		EntryShieldDuration = Type.optional(Type.numberPositive),
		IdentityKey = Type.optional(CharacterType.IdentityKey),
	}),
	-- a duration is written onto the spots, which are only known by their tag
	function(value: Rule): (boolean, string?)
		if value.ShieldDuration ~= nil and value.Tag == nil then
			return false, `a shield duration without the tag of the spots it's for`
		end
		return true
	end
)
-- where + as whom an avatar comes in is the game's own, the rule of another game is never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		return require("@self/SHL1")
	end,
	shl2 = function(): Rule
		return require("@self/SHL2")
	end,
	shl3 = function(): Rule
		return require("@self/SHL3")
	end,
})
assert(isRule(RULE))
-- Variables
-- References
-- Private Functions
-- Class
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	TAG = RULE.Tag,
	SHIELD_DURATION = RULE.ShieldDuration,
	ENTRY_SHIELD_DURATION = RULE.EntryShieldDuration,
	IDENTITY_KEY = RULE.IdentityKey,
	-- who a character is worn as from the start: the identity its avatar comes back in, + its hero in a game where it
	-- comes back as whoever it was
	START_IDENTITY_KEY = (RULE.IdentityKey or "Main") :: IdentityKey,
}

return Module
