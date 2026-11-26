--!strict
-- Services
-- Packages
-- Modules
-- Types
local DisasterType = require("@game/ReplicatedStorage/Shared/Type/Disaster")
type Rebuild = DisasterType.Rebuild
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- when what was blown up is looked at again + how it comes back up. nothing in here keeps time
local Util = {}

-- seconds until the next look, from how long the server has been at it. the looks are on a beat of its own that no
-- blast moves: what fell right after one is gone for all of the interval, what fell right before one hardly at all
function Util.getDelay(elapsed: number, rebuild: Rebuild): number
	if elapsed < rebuild.FirstDelay then
		return rebuild.FirstDelay - elapsed
	end
	return rebuild.Interval - (elapsed - rebuild.FirstDelay) % rebuild.Interval
end

-- studs under its place it still is, that many seconds into its way up: fast at first + slower the closer it gets
function Util.getDrop(elapsed: number, rebuild: Rebuild): number
	local remaining = 1 - math.clamp(elapsed / rebuild.RiseDuration, 0, 1)
	return rebuild.Depth * remaining * remaining
end

return Util
