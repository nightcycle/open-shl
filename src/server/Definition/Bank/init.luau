--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- the front door of the building, it's in the way while the bank is shut
export type Door = {
	OpenTransparency: number,
	ShutTransparency: number,
}
-- a half of the door of a vault
export type VaultDoor = {
	Duration: number, -- seconds it slides for, either way
}
-- what sweeps the hall in front of the vaults
export type Beam = {
	Damage: number, -- health it takes off whoever it goes through, the same off everybody
	Cooldown: number, -- seconds it then spares them for
	-- a beam goes at its own share of the pace the map gives it, rolled once as the server starts
	Pace: { Min: number, Max: number },
}
-- the bank of a game: it stands open until it's robbed, then it's shut until a morning of the game's clock
export type Rule = {
	-- seconds into the life of the server the first look is taken at, + seconds between two looks
	StartDelay: number,
	CheckInterval: number,
	-- a look that finds a robbery older than this many seconds ends it
	MaxDuration: number,
	-- the credits each vault holds as the bank opens, by the number of the vault
	Vaults: { number },
	-- what a pad hands each of those who stand on it, + the seconds between two rounds of it
	PayAmount: number,
	PayInterval: number,
	-- the side that robs it, any other guards it
	RobberTeamId: TeamId,
	-- the hours of the day a shut bank opens in
	ReopenHour: { Min: number, Max: number },
	Door: Door,
	VaultDoor: VaultDoor,
	Beam: Beam,
	-- what the side that's called on reads as a robbery starts
	Alert: string,
}
-- Constants
local isRule = Type.strictInterface({
	StartDelay = Type.numberMin(0),
	CheckInterval = Type.numberPositive,
	MaxDuration = Type.numberPositive,
	Vaults = Type.array(Type.intersection(Type.integer, Type.numberPositive)),
	PayAmount = Type.intersection(Type.integer, Type.numberPositive),
	PayInterval = Type.numberPositive,
	RobberTeamId = CombatType.TeamId,
	ReopenHour = Type.strictInterface({
		Min = Type.numberConstrained(0, 24),
		Max = Type.numberConstrained(0, 24),
	}),
	Door = Type.strictInterface({
		OpenTransparency = Type.numberConstrained(0, 1),
		ShutTransparency = Type.numberConstrained(0, 1),
	}),
	VaultDoor = Type.strictInterface({
		Duration = Type.numberPositive,
	}),
	Beam = Type.strictInterface({
		Damage = Type.numberPositive,
		Cooldown = Type.numberMin(0),
		Pace = Type.strictInterface({
			Min = Type.numberPositive,
			Max = Type.numberPositive,
		}),
	}),
	Alert = Type.string,
})
-- a pace is rolled in whole hundredths, as the old place did
local PACE_STEP = 100
-- the bank of a game is its own, the rule of another game is never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		error(`shl1 has no bank`)
	end,
	shl2 = function(): Rule
		error(`shl2 has no bank`)
	end,
	shl3 = function(): Rule
		return require("@self/SHL3")
	end,
})
assert(isRule(RULE))
assert(RULE.ReopenHour.Min < RULE.ReopenHour.Max, `the bank opens in no hour`)
assert(RULE.Beam.Pace.Min <= RULE.Beam.Pace.Max, `the pace of a beam has no range`)
TableUtil.deepFreeze(RULE)
-- Variables
-- References
-- Private Functions
-- Class
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	START_DELAY = RULE.StartDelay,
	CHECK_INTERVAL = RULE.CheckInterval,
	MAX_DURATION = RULE.MaxDuration,
	VAULTS = RULE.Vaults,
	PAY_AMOUNT = RULE.PayAmount,
	PAY_INTERVAL = RULE.PayInterval,
	ROBBER_TEAM_ID = RULE.RobberTeamId,
	REOPEN_HOUR = RULE.ReopenHour,
	DOOR = RULE.Door,
	VAULT_DOOR = RULE.VaultDoor,
	BEAM = RULE.Beam,
	ALERT = RULE.Alert,
	-- the share of its map's pace a beam sweeps at for the life of the server
	rollPace = function(random: Random): number
		local pace = RULE.Beam.Pace
		return random:NextInteger(math.round(pace.Min * PACE_STEP), math.round(pace.Max * PACE_STEP)) / PACE_STEP
	end,
}

return Module
