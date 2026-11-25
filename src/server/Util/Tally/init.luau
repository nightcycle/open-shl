--!strict
-- Services
-- Packages
-- Modules
-- Types
-- how much health each player took off a body
export type Ledger = { [Player]: number }
-- Constants
-- Variables
-- the bodies somebody keeps count on, each with what was taken off it since it was last asked for
local Ledgers: { [Model]: Ledger } = {}
-- References
-- Private Functions
-- Class
-- the server's count of who took how much off a body, for whoever shares something out by it. it's kept where the
-- health comes off, so it's health that was there to take: no more than the body had left + none off one that's down
local Util = {}

-- from here on what's taken off the body is counted. whoever opens it closes it, nothing else lets go of the body
function Util.open(body: Model)
	if not Ledgers[body] then
		Ledgers[body] = {}
	end
end

-- nothing is kept for a body nobody opened, which is every avatar + every body of a game that shares nothing out
function Util.add(body: Model, player: Player, amount: number)
	local ledger = Ledgers[body]
	if ledger then
		ledger[player] = (ledger[player] or 0) + amount
	end
end

-- what was counted since the body was opened or last asked for, the count starts over from nothing. a player who
-- left since is still in it: who of them is paid is up to whoever asks
function Util.take(body: Model): Ledger
	local ledger = Ledgers[body]
	if not ledger then
		return table.freeze({} :: Ledger)
	end
	Ledgers[body] = {}
	return table.freeze(ledger)
end

-- the count is over + what was left of it is gone
function Util.close(body: Model)
	Ledgers[body] = nil
end

return Util
