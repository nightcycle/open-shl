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
-- heroes + villains, in the two colors its old place listed them by. the old place left it to the engine where
-- somebody who joins goes, which is the side with fewer: with both as full it's the heroes here, so whoever is
-- first in starts out in the city + not alone in a cell. somebody may leave for a side that has two more than
-- theirs, themselves counted, + no more: three against five lets a hero go, two against six doesn't
return table.freeze({
	Sides = table.freeze({
		table.freeze({ Id = "Heroes" :: TeamId, Name = "Heroes", BrickColorNumber = 307 }),
		table.freeze({ Id = "Villains" :: TeamId, Name = "Villains", BrickColorNumber = 1004 }),
	}),
	JoinTeamId = "Heroes" :: TeamId,
	MaxLead = 2,
	RefusalText = "Teams are too unbalanced to switch right now",
})
