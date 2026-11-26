--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
-- only a game with crime has anything to hold this to, + its disasters raise as they're read in any other
if not GameDefinition.FEATURES.Crime then
	return {} :: TestMap
end
local DisasterDefinition = require("@game/ReplicatedStorage/Shared/Definition/Disaster")
local PayoutUtil = require("@game/ServerScriptService/Server/Service/Crime/Disaster/Payout")
local RebuildUtil = require("@game/ServerScriptService/Server/Service/Crime/Disaster/Blast/Rebuild")
type Rebuild = DisasterDefinition.Rebuild
-- Constants
local EPSILON = 0.000001
-- Variables
-- References
-- Private Functions
-- a share only ever tells players apart, so anything stands in for one: the engine makes no player to order
local function newPlayer(): Player
	return (Instance.new("Folder") :: any) :: Player
end

local function getCount(shares: PayoutUtil.Shares): number
	local count = 0
	for _ in shares do
		count += 1
	end
	return count
end

-- the beat of the one disaster of the game that's rebuilt
local function getRebuild(): Rebuild
	for _, disaster in DisasterDefinition.list() do
		local consequence = disaster.Consequence
		if consequence.Type == "Blast" then
			return consequence.Rebuild
		end
	end
	error(`no disaster of the game ends in a blast`)
end
-- Class
local Tests: TestMap = {
	-- two who took a target down between them share its pool by what each took
	Shares = SpecUtil.newScenario(function()
		local player, rival = newPlayer(), newPlayer()
		local shares = PayoutUtil.getShares({ [player] = 1500, [rival] = 500 }, 3)
		assert(table.isfrozen(shares), `the shares aren't frozen`)
		assert(getCount(shares) == 2, `two are paid as {getCount(shares)}`)
		assert(shares[player] == 4500, `1500 of 2000 at 3 a point pays {shares[player]}`)
		assert(shares[rival] == 1500, `500 of 2000 at 3 a point pays {shares[rival]}`)
		-- all of a target to one of them is all of its pool
		local disasters = DisasterDefinition.list()
		local refinery = assert(disasters.RefineryExplosion, `the game has no refinery`)
		local all = PayoutUtil.getShares({ [player] = refinery.MaxHealth }, refinery.PoolScale)
		assert(all[player] == 4500, `the whole refinery pays {all[player]}`)
	end),

	-- a share is whole credits, each rounded down by itself
	Floors = SpecUtil.newScenario(function()
		local player, rival = newPlayer(), newPlayer()
		local shares = PayoutUtil.getShares({ [player] = 333, [rival] = 0.1 }, 4.5)
		assert(shares[player] == 1498, `333 at 4.5 a point pays {shares[player]}`)
		assert(shares[rival] == 0, `a tenth of a point pays {shares[rival]}`)
	end),

	-- nobody took anything off it, nobody is paid
	Nobody = SpecUtil.newScenario(function()
		assert(getCount(PayoutUtil.getShares({}, 3)) == 0, `a target nobody hit pays somebody`)
	end),

	-- what was blown up is looked at on a beat of the server's own, however long ago it fell
	Looks = SpecUtil.newScenario(function()
		local rebuild = getRebuild()
		local first, interval = rebuild.FirstDelay, rebuild.Interval
		assert(RebuildUtil.getDelay(0, rebuild) == first, `the first look isn't {first} seconds in`)
		assert(math.abs(RebuildUtil.getDelay(first - 1, rebuild) - 1) < EPSILON, `a second before it isn't one off`)
		-- at a look the next one is a whole interval off, never none
		assert(RebuildUtil.getDelay(first, rebuild) == interval, `the look after the first isn't an interval on`)
		assert(
			math.abs(RebuildUtil.getDelay(first + 10, rebuild) - (interval - 10)) < EPSILON,
			`ten seconds after a look the next isn't ten short of an interval`
		)
		-- walked from one to the next, they're where they belong + none is skipped
		local elapsed = 0
		for look = 0, 5 do
			elapsed += RebuildUtil.getDelay(elapsed, rebuild)
			assert(math.abs(elapsed - (first + look * interval)) < EPSILON, `look {look + 1} is {elapsed} seconds in`)
		end
	end),

	-- it comes up from its depth to its place, fast at first, + is never under or over either
	Rise = SpecUtil.newScenario(function()
		local rebuild = getRebuild()
		local depth, duration = rebuild.Depth, rebuild.RiseDuration
		assert(RebuildUtil.getDrop(0, rebuild) == depth, `it doesn't start {depth} studs down`)
		assert(RebuildUtil.getDrop(duration, rebuild) == 0, `it isn't at its place after {duration} seconds`)
		assert(RebuildUtil.getDrop(duration * 2, rebuild) == 0, `it goes on past its place`)
		assert(RebuildUtil.getDrop(-1, rebuild) == depth, `it starts under its depth`)
		-- half the time in it's three quarters of the way up
		assert(math.abs(RebuildUtil.getDrop(duration / 2, rebuild) - depth / 4) < EPSILON, `it isn't eased out`)
		local prior = depth
		for step = 1, 240 do
			local drop = RebuildUtil.getDrop(step * duration / 240, rebuild)
			assert(drop <= prior, `it sinks at step {step}`)
			prior = drop
		end
	end),
}

return Tests
