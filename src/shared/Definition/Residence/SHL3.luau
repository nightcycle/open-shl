--!strict
-- Services
-- Packages
-- Modules
-- Types
local ResidenceType = require("@game/ReplicatedStorage/Shared/Type/Residence")
type Wire = ResidenceType.Wire
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a flat of superhero life 3 is named after its anchor in the apartment building
local Wire: Wire = table.freeze({
	ResidenceId = ResidenceType.SHL3ResidenceId,
	State = ResidenceType.SHL3State,
})

return Wire
