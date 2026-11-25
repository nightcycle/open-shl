--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
type Appearance = AppearanceType.Appearance
type BaseLayout = BaseType.BaseLayout

local Types = {}

-- what a residence is to the code every game with residences shares: which one it is + whose. the id is a text, which
-- texts name a residence is the game's to say. what a client builds one from comes on top of it + is the game's own
export type State = {
	ResidenceId: string,
	OwnerUserId: number,
}
-- of whatever game: only the two every state has are looked at
Types.State = Type.interface({
	ResidenceId = Type.string,
	OwnerUserId = Type.integer,
})

-- everything a client of superhero life 2 builds a residence from: an apartment over a base its owner furnishes. the
-- server only hands it to somebody who may walk in
export type SHL2State = {
	ResidenceId: string, -- a door of the apartment lobby
	OwnerUserId: number,
	Layout: BaseLayout,
	Costumes: { [string]: Appearance }, -- what the suit displays wear, keyed by the character id they hold
}
Types.SHL2State = Type.strictInterface({
	ResidenceId = BaseType.ResidenceId,
	OwnerUserId = Type.integer,
	Layout = BaseType.BaseLayout,
	Costumes = Type.map(Type.string, AppearanceType.Appearance),
})

-- a flat of superhero life 3 is named after the anchor of the map it's built at
local SHL3_ID_PATTERN = "^apartment%-(%d+)$"
local SHL3_ID_COUNT = 24
Types.SHL3ResidenceId = function(value: unknown): (boolean, string?)
	if type(value) ~= "string" then
		return false, `string expected, got {typeof(value)}`
	end
	local digits = string.match(value, SHL3_ID_PATTERN)
	local index = if digits then tonumber(digits) else nil
	-- one name per flat: "apartment-01" is none
	if not index or index < 1 or index > SHL3_ID_COUNT or tostring(index) ~= digits then
		return false, `"{value}" isn't a flat`
	end
	return true
end

-- everything a client of superhero life 3 builds a flat from: its owner picks none of what's in it, only how good a
-- one they bought
export type SHL3State = {
	ResidenceId: string, -- an anchor of the apartment building
	OwnerUserId: number,
	Tier: number, -- 1 for the cheapest
}
Types.SHL3State = Type.strictInterface({
	ResidenceId = Types.SHL3ResidenceId,
	OwnerUserId = Type.integer,
	Tier = Type.intersection(Type.integer, Type.numberPositive),
})

-- what a game lets across the wire of its residences: what names one + what a client is handed to build it from
export type Wire = {
	ResidenceId: (value: unknown) -> (boolean, string?),
	State: (value: unknown) -> (boolean, string?),
}
Types.Wire = Type.strictInterface({
	ResidenceId = Type.callback,
	State = Type.callback,
})

return Types
