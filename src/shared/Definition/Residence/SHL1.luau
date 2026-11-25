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
local function refuse(_value: unknown): (boolean, string?)
	return false, `shl1's flats are scenery`
end
-- Class
-- nobody lives in a flat of superhero life: nothing names one + nothing is built in one
local Wire: Wire = table.freeze({
	ResidenceId = refuse,
	State = refuse,
})

return Wire
