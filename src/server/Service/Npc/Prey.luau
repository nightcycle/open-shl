--!strict
-- Services
-- Packages
-- Modules
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- somebody a walker might go after, as the server has them right now
export type Candidate = {
	Position: Vector3,
	TeamId: TeamId?,
	IsAlive: boolean,
	-- the rule of the game keeps the walker from hurting them: they sit in a menu, they're held + made no trouble
	IsSheltered: boolean,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- who a walker hunts
local Module = {}

-- which of them it goes after: the nearest one of that side it sees that's up + that it'd be let hurt, the first of
-- two that are as near. nil with nobody to hunt, which is when it stands
Module.pick = function(position: Vector3, candidates: { Candidate }, sight: number, teamId: TeamId): number?
	local nearestIndex: number? = nil
	local nearestDistance = sight
	for index, candidate in candidates do
		if candidate.TeamId == teamId and candidate.IsAlive and not candidate.IsSheltered then
			local distance = (candidate.Position - position).Magnitude
			if distance < nearestDistance then
				nearestIndex = index
				nearestDistance = distance
			end
		end
	end
	return nearestIndex
end

return Module
