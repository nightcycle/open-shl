--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

-- every place is the same code built for one of these
export type GameId = "shl1" | "shl2" | "shl3"
Types.GameId = Type.literal("shl1", "shl2", "shl3")

-- what one game runs + another may not. a service, a container or a button only starts where its feature is on. every
-- game answers for every one of them, so a new one can't be forgotten for any
export type Features = {
	Residences: boolean,
	Quests: boolean,
	Tutorial: boolean,
	Music: boolean,
	Uniforms: boolean,
	CustomServers: boolean,
	Teams: boolean,
	Jobs: boolean,
	Props: boolean,
	PrivateServerToggle: boolean,
	Roleplay: boolean, -- masks, cuffs + expressions
	ModeSelect: boolean, -- the pick between its places on the way in
	DayNight: boolean, -- a clock that lights the lamps + the windows
	Fixtures: boolean, -- what a map tags for the server to run: beacons, gates, hazards, a reactor + what's put back up
	PlayerMode: boolean, -- who fights + who sits fights out is each player's own pick, in one place
}
Types.Features = Type.strictInterface({
	Residences = Type.boolean,
	Quests = Type.boolean,
	Tutorial = Type.boolean,
	Music = Type.boolean,
	Uniforms = Type.boolean,
	CustomServers = Type.boolean,
	Teams = Type.boolean,
	Jobs = Type.boolean,
	Props = Type.boolean,
	PrivateServerToggle = Type.boolean,
	Roleplay = Type.boolean,
	ModeSelect = Type.boolean,
	DayNight = Type.boolean,
	Fixtures = Type.boolean,
	PlayerMode = Type.boolean,
})

-- a way to get a value for every game. only the one of the game that's built is ever called, so what another's needs
-- doesn't have to be in the place
export type Loaders<V> = {
	shl1: () -> V,
	shl2: () -> V,
	shl3: () -> V,
}
Types.Loaders = Type.strictInterface({
	shl1 = Type.callback,
	shl2 = Type.callback,
	shl3 = Type.callback,
})

-- the values of the games that don't go by what all of them share
export type Tuning<V> = {
	shl1: V?,
	shl2: V?,
	shl3: V?,
}
Types.Tuning = Type.strictInterface({
	shl1 = Type.optional(Type.any),
	shl2 = Type.optional(Type.any),
	shl3 = Type.optional(Type.any),
})

return Types
