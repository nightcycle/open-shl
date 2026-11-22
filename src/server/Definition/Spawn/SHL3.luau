--!strict
-- Services
-- Packages
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the same spots in both modes: points in the air over the roofs of the city, an avatar drops from one. it comes
-- back as the hero whoever it went down as, with no shield: the old game took its force field off again the moment
-- an avatar was dressed, which on the way back was right away. it had no health bar of its own either: the one of
-- the engine stood over whoever was hurt, read from as far off as the old place had it set
return table.freeze({
	Tag = MapDefinition.Spawn,
	ShieldDuration = 0,
	EntryShieldDuration = nil,
	IdentityKey = "Main" :: "Main",
	HealthDisplayDistance = 100,
})
