--!strict
-- Services
-- Packages
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
-- Constants
-- the old game kept a force field on whoever came in for this long, the first time + every time they came back
local SHIELD_DURATION = 10
-- Variables
-- References
-- Private Functions
-- Class
-- an avatar comes in on one of the four sides of the garden, wherever the engine picks, + always as the secret
-- identity: the hero is only ever somebody a player turns into. nobody is hurt under the force field of their spot.
-- whoever makes a character does it behind a menu for longer than that lasts, so they get it again as they're let out
return table.freeze({
	Tag = MapDefinition.Spawn,
	ShieldDuration = SHIELD_DURATION,
	EntryShieldDuration = SHIELD_DURATION,
	IdentityKey = "Secret" :: "Secret",
	HealthDisplayDistance = nil,
})
