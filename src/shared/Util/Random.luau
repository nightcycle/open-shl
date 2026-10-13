--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.newSeed(rng: Random): number
	return rng:NextInteger(1_000, 1_000_000)
end

return Util
