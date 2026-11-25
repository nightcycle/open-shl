--!strict
-- Services
-- Packages
-- Modules
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local TallyUtil = require("@game/ServerScriptService/Server/Util/Tally")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- a count only ever tells players apart, so anything stands in for one: the engine makes no player to order
local function newPlayer(): Player
	return (Instance.new("Folder") :: any) :: Player
end

local function getCount(ledger: TallyUtil.Ledger): number
	local count = 0
	for _ in ledger do
		count += 1
	end
	return count
end
-- Class
return {
	-- nothing is kept for a body nobody opened
	Unopened = SpecUtil.newScenario(function()
		local body, player = Instance.new("Model"), newPlayer()
		TallyUtil.add(body, player, 10)
		assert(getCount(TallyUtil.take(body)) == 0, `a body nobody opened has a count`)
		-- what came off it before it was opened is no part of the count either
		TallyUtil.open(body)
		assert(getCount(TallyUtil.take(body)) == 0, `a body that was just opened has a count`)
		TallyUtil.close(body)
	end),

	-- what two players take adds up apart, on that body alone
	Apart = SpecUtil.newScenario(function()
		local body, other = Instance.new("Model"), Instance.new("Model")
		local player, rival = newPlayer(), newPlayer()
		TallyUtil.open(body)
		TallyUtil.open(other)
		TallyUtil.add(body, player, 10)
		TallyUtil.add(body, rival, 2.5)
		TallyUtil.add(body, player, 5)
		TallyUtil.add(other, rival, 40)
		-- opening it again starts nothing over
		TallyUtil.open(body)
		local ledger = TallyUtil.take(body)
		assert(table.isfrozen(ledger), `the count isn't frozen`)
		assert(getCount(ledger) == 2, `two players are counted as {getCount(ledger)}`)
		assert(ledger[player] == 15, `two hits of one player come to {ledger[player]}`)
		assert(ledger[rival] == 2.5, `the hit of the other comes to {ledger[rival]}`)
		local otherLedger = TallyUtil.take(other)
		assert(getCount(otherLedger) == 1 and otherLedger[rival] == 40, `the count of a body has that of another`)
		TallyUtil.close(body)
		TallyUtil.close(other)
	end),

	-- whoever asks gets what there is + leaves nothing behind, the body is counted on
	Taken = SpecUtil.newScenario(function()
		local body, player = Instance.new("Model"), newPlayer()
		TallyUtil.open(body)
		TallyUtil.add(body, player, 10)
		assert(TallyUtil.take(body)[player] == 10, `the count isn't what was added`)
		assert(getCount(TallyUtil.take(body)) == 0, `a count that was taken is still there`)
		TallyUtil.add(body, player, 3)
		assert(TallyUtil.take(body)[player] == 3, `the count after one was taken has the one before in it`)
		TallyUtil.close(body)
	end),

	-- a body that's closed is one nobody opened
	Closed = SpecUtil.newScenario(function()
		local body, player = Instance.new("Model"), newPlayer()
		TallyUtil.open(body)
		TallyUtil.add(body, player, 10)
		TallyUtil.close(body)
		assert(getCount(TallyUtil.take(body)) == 0, `a closed body kept its count`)
		TallyUtil.add(body, player, 10)
		assert(getCount(TallyUtil.take(body)) == 0, `a closed body is counted on`)
		-- closing what's closed is nothing
		TallyUtil.close(body)
	end),
}
