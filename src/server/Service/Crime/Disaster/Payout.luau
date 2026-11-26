--!strict
-- Services
-- Packages
-- Modules
-- Types
-- the credits each of them is handed
export type Shares = { [Player]: number }
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- how the pool of a target that fell is shared out
local Util = {}

-- everybody gets as many credits for a point of health they took as the pool has for one, whole credits + rounded
-- down for each by themselves. the points were counted as they came off, so all of them together never come to more
-- than the target had: the pool is what it's said to be whatever the size of the last hit
function Util.getShares(dealt: { [Player]: number }, scale: number): Shares
	local shares: Shares = {}
	for player, amount in dealt do
		shares[player] = math.floor(scale * amount)
	end
	return table.freeze(shares)
end

return Util
