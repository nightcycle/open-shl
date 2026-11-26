--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
local Types = {}

-- the ball of light a blast is seen by, every client draws its own
export type Fireball = {
	Size: number, -- studs across at its widest
	GrowDuration: number, -- seconds it takes to get there, + to turn from white to its color
	FadeDuration: number, -- seconds until nothing is seen of it
	Lifetime: number, -- seconds until it's gone
	Color: Color3,
}
Types.Fireball = Type.strictInterface({
	Size = Type.numberPositive,
	GrowDuration = Type.numberPositive,
	FadeDuration = Type.numberPositive,
	Lifetime = Type.numberPositive,
	Color = Type.Color3,
})

-- when what was blown up stands again: on a beat of the server's own, not so long after it fell
export type Rebuild = {
	FirstDelay: number, -- seconds into the life of the server the first look is taken at
	Interval: number, -- seconds between two looks
	Depth: number, -- studs under its place it comes back in at
	RiseDuration: number, -- seconds it takes up to its place
}
Types.Rebuild = Type.strictInterface({
	FirstDelay = Type.numberMin(0),
	Interval = Type.numberPositive,
	Depth = Type.numberMin(0),
	RiseDuration = Type.numberPositive,
})

-- what falls with the target is thrown about + whoever is near goes down with it
export type Blast = {
	Type: "Blast",
	Radius: number, -- studs around the target nobody is left standing in
	Pressure: number, -- what the engine throws the wreck with
	DebrisLifetime: number, -- seconds the wreck lies about for, + is deadly to touch
	DebrisTeamId: TeamId, -- the side the wreck takes down
	Fireball: Fireball,
	Rebuild: Rebuild,
}
Types.Blast = Type.strictInterface({
	Type = Type.literal("Blast"),
	Radius = Type.numberPositive,
	Pressure = Type.numberPositive,
	DebrisLifetime = Type.numberPositive,
	DebrisTeamId = CombatType.TeamId,
	Fireball = Types.Fireball,
	Rebuild = Types.Rebuild,
})

-- bodies nobody plays come out of the ground of the map
export type Rise = {
	Type: "Rise",
	NpcId: string,
	SmokeDuration: number, -- seconds the ground smokes for before they're out
	Offset: Vector3, -- from where the map marks to where one comes in
	Lifetime: number, -- seconds one walks for
	ResetDelay: number, -- seconds from when they're out until the target stands again
}
Types.Rise = Type.strictInterface({
	Type = Type.literal("Rise"),
	NpcId = Type.string,
	SmokeDuration = Type.numberMin(0),
	Offset = Type.Vector3,
	Lifetime = Type.numberPositive,
	ResetDelay = Type.numberPositive,
})

-- what the town gets for a target that fell
export type Consequence = Blast | Rise
Types.Consequence = Type.union(Types.Blast, Types.Rise)

-- something of the map one side wears down + the other keeps standing
export type Disaster = {
	MaxHealth: number,
	-- the credits there are to share for each point of its health: whoever took one off it gets that many
	PoolScale: number,
	GuardTeamId: TeamId, -- the side it stands for, which is the side that can't hurt it
	Alert: string, -- what that side reads once the first of its health is gone
	Consequence: Consequence,
	-- a target that isn't takes nothing + stands for good: what would follow its fall isn't in the game yet
	IsArmed: boolean,
}
Types.Disaster = Type.strictInterface({
	MaxHealth = Type.numberPositive,
	PoolScale = Type.numberPositive,
	GuardTeamId = CombatType.TeamId,
	Alert = Type.string,
	Consequence = Types.Consequence,
	IsArmed = Type.boolean,
})

-- the bar over a target, it blinks whenever health comes off
export type Bar = {
	FlashDuration: number, -- seconds
	FlashColor: Color3,
	Color: Color3,
}
Types.Bar = Type.strictInterface({
	FlashDuration = Type.numberPositive,
	FlashColor = Type.Color3,
	Color = Type.Color3,
})

-- the disasters of a game by the id its map marks their target with
export type Catalogue = {
	Disasters: { [string]: Disaster },
	Bar: Bar,
}
Types.Catalogue = Type.strictInterface({
	Disasters = Type.map(Type.string, Types.Disaster),
	Bar = Types.Bar,
})

return Types
