--!strict
-- Services
-- Packages
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type AccessCatalogue = EconomyType.AccessCatalogue
-- Constants
-- nothing is held back yet: what its passes + its group open is written down here once they're asked for
local CATALOGUE: AccessCatalogue = {
	PriceAdjust = 1,
	Currency = "Credits",
	Listings = {},
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
