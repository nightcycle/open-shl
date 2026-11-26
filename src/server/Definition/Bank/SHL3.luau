--!strict
-- Services
-- Packages
-- Modules
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the bank of valor city, every number as its old place had it. it's looked at every five seconds from fifteen in:
-- a robbery is over once the vaults are empty, every robber went down or a look finds it older than five minutes,
-- which the 61st is the first to. a pad hands whoever stands on it 100 every three seconds out of what its vault
-- holds. the old place meant it to open again between nine + ten of the city's clock + read a clock that wasn't
-- there. a beam takes 35 off whoever it sweeps through, then spares them for a second + a half, + goes at anything
-- from 0.6 to 1.4 of the pace its map gives it. a half of a vault door slides for six seconds
return table.freeze({
	StartDelay = 15,
	CheckInterval = 5,
	MaxDuration = 300,
	Vaults = table.freeze({ 300, 500, 700 }),
	PayAmount = 100,
	PayInterval = 3,
	RobberTeamId = "Villains" :: TeamId,
	ReopenHour = table.freeze({ Min = 9, Max = 10 }),
	Door = table.freeze({ OpenTransparency = 1, ShutTransparency = 0 }),
	VaultDoor = table.freeze({ Duration = 6 }),
	Beam = table.freeze({
		Damage = 35,
		Cooldown = 1.5,
		Pace = table.freeze({ Min = 0.6, Max = 1.4 }),
	}),
	Alert = "Villains are trying to rob the bank!",
})
