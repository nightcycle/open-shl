--!strict
-- Services
-- Packages
-- Modules
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- how many players each side has
export type Counts = { [TeamId]: number }
-- Constants
-- Variables
-- References
-- Private Functions
-- a side that's read off a call or out of a list is written down with its type every time: the checker only knows
-- one that isn't for a string
local function getOther(teamId: TeamId): TeamId
	local otherTeamId: TeamId = if teamId == "Heroes" then "Villains" else "Heroes"
	return otherTeamId
end

-- where somebody who comes in goes: the side with fewer, + the one the game says while neither is ahead
local function getJoinTeamId(counts: Counts, tieTeamId: TeamId): TeamId
	local otherTeamId: TeamId = getOther(tieTeamId)
	return if (counts[otherTeamId] or 0) < (counts[tieTeamId] or 0) then otherTeamId else tieTeamId
end

-- if somebody of that side may leave it for the other: not while the other is ahead of theirs by more than the lead
-- the game lets a side have, whoever asks counted with their own
local function getIfSwitchAllowed(counts: Counts, fromTeamId: TeamId, maxLead: number): boolean
	local toTeamId: TeamId = getOther(fromTeamId)
	return (counts[toTeamId] or 0) <= (counts[fromTeamId] or 0) + maxLead
end
-- Class
-- who goes where for the two sides to stay near each other in number: nothing in here knows a player. every function
-- is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Util = {
	getOther = getOther,
	getJoinTeamId = getJoinTeamId,
	getIfSwitchAllowed = getIfSwitchAllowed,
}

return Util
