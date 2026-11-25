--!strict
-- Services
-- Packages
-- Modules
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local ResidenceType = require("@game/ReplicatedStorage/Shared/Type/Residence")
type Wire = ResidenceType.Wire
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a residence of superhero life 2 is named after its door in the apartment lobby
local Wire: Wire = table.freeze({
	ResidenceId = BaseType.ResidenceId,
	State = ResidenceType.SHL2State,
})

return Wire
