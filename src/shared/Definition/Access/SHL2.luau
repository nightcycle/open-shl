--!strict
-- Services
-- Packages
-- Modules
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type AccessCatalogue = EconomyType.AccessCatalogue
-- Constants
-- nothing a character wears or wields is held back, what it sells is furniture
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
