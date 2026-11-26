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
local BankDefinition = require("@game/ServerScriptService/Server/Definition/Bank")
local DisasterDefinition = require("@game/ReplicatedStorage/Shared/Definition/Disaster")
local PayoutUtil = require("@game/ServerScriptService/Server/Service/Crime/Disaster/Payout")
local RebuildUtil = require("@game/ServerScriptService/Server/Service/Crime/Disaster/Blast/Rebuild")
local RobberyUtil = require("@game/ServerScriptService/Server/Service/Crime/Bank/Robbery")
local SweepUtil = require("@game/ReplicatedStorage/Shared/Util/Sweep")
type TeamId = "Heroes" | "Villains"
type Rebuild = DisasterDefinition.Rebuild
-- Constants
local EPSILON = 0.000001
-- the side that robs the bank + the one that doesn't
local ROBBER_TEAM_ID: TeamId = BankDefinition.ROBBER_TEAM_ID
local GUARD_TEAM_ID: TeamId = if ROBBER_TEAM_ID == "Villains" then "Heroes" else "Villains"
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

-- looked at as often as it takes for the looks to add up to that many seconds. true if any of them shut it
local function lookFor(state: RobberyUtil.State, duration: number): (RobberyUtil.State, boolean)
	local interval = BankDefinition.CHECK_INTERVAL
	local isShut = false
	for _ = 1, duration / interval do
		local isOver: boolean
		state, isOver = RobberyUtil.step(state, interval)
		isShut = isShut or isOver
	end
	return state, isShut
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

	-- the first robber into an open bank has the town told, once a robbery: nobody is on a list twice
	Robbers = SpecUtil.newScenario(function()
		local robber, accomplice, guard = newPlayer(), newPlayer(), newPlayer()
		local state = RobberyUtil.new()
		assert(table.isfrozen(state) and state.IsOpen, `a bank doesn't start open`)
		local isFirst: boolean
		state, isFirst = RobberyUtil.enter(state, guard, GUARD_TEAM_ID)
		assert(not isFirst and state.Guards[guard] == false, `a guard that walks in sets the alarm off`)
		state, isFirst = RobberyUtil.enter(state, robber, ROBBER_TEAM_ID)
		assert(isFirst and state.Robbers[robber] == false and state.IsAlarmed, `the first robber sets no alarm off`)
		local again: RobberyUtil.State
		again, isFirst = RobberyUtil.enter(state, robber, ROBBER_TEAM_ID)
		assert(not isFirst and again == state, `a robber is on the list twice`)
		state, isFirst = RobberyUtil.enter(state, accomplice, ROBBER_TEAM_ID)
		assert(not isFirst and state.Robbers[accomplice] == false, `the second robber sets the alarm off again`)
		-- one that went down stays on the list as down, a walk back in changes nothing
		state = RobberyUtil.down(state, robber)
		assert(state.Robbers[robber] == true, `a robber that went down is still up`)
		again, isFirst = RobberyUtil.enter(state, robber, ROBBER_TEAM_ID)
		assert(not isFirst and again == state, `a robber that went down is on the list again`)
		assert(RobberyUtil.down(state, newPlayer()) == state, `somebody who never came in went down in it`)
		-- shut, it puts outside whoever is still up + is as it was before anybody came
		local filed: RobberyUtil.Filed
		state, filed = RobberyUtil.close(state)
		assert(#filed.Robbers == 1 and filed.Robbers[1] == accomplice, `the robber that's up isn't put outside`)
		assert(#filed.Guards == 1 and filed.Guards[1] == guard, `the guard isn't put outside`)
		assert(not state.IsOpen and not state.IsAlarmed and next(state.Robbers) == nil, `a shut bank keeps its list`)
		state, isFirst = RobberyUtil.enter(state, robber, ROBBER_TEAM_ID)
		assert(not isFirst and next(state.Robbers) == nil, `somebody walks into a shut bank`)
		-- the next robbery has the town told again
		state, isFirst = RobberyUtil.enter(RobberyUtil.new(), robber, ROBBER_TEAM_ID)
		assert(isFirst, `the robbery after one sets no alarm off`)
	end),

	-- a robbery is over once every robber went down, the vaults are empty or the looks at it add up to too long
	Ends = SpecUtil.newScenario(function()
		local robber, accomplice, guard = newPlayer(), newPlayer(), newPlayer()
		local interval, maxDuration = BankDefinition.CHECK_INTERVAL, BankDefinition.MAX_DURATION
		-- nobody robs it: no clock runs, however long it's looked at
		local empty, isShut = lookFor(RobberyUtil.new(), maxDuration * 3)
		assert(not isShut and empty.Elapsed == 0, `a bank nobody robs shuts`)
		local guarded = RobberyUtil.enter(RobberyUtil.new(), guard, GUARD_TEAM_ID)
		guarded, isShut = lookFor(guarded, maxDuration * 3)
		assert(not isShut and guarded.Elapsed == 0, `a bank only its guards are in shuts`)
		-- a robber is in: the look that finds it older than it may get shuts it, the one before doesn't
		local state = RobberyUtil.enter(RobberyUtil.new(), robber, ROBBER_TEAM_ID)
		state = RobberyUtil.enter(state, accomplice, ROBBER_TEAM_ID)
		local late: RobberyUtil.State
		late, isShut = lookFor(state, maxDuration)
		assert(not isShut and late.Elapsed == maxDuration, `{maxDuration} seconds of looks shut it`)
		late, isShut = RobberyUtil.step(late, interval)
		assert(isShut, `{maxDuration + interval} seconds of looks don't shut it`)
		-- one of two down is a robbery still, both down is none
		local isOver: boolean
		state = RobberyUtil.down(state, robber)
		state, isOver = RobberyUtil.step(state, interval)
		assert(not isOver, `one robber of two down shuts it`)
		state = RobberyUtil.down(state, accomplice)
		state, isOver = RobberyUtil.step(state, interval)
		assert(isOver, `every robber down doesn't shut it`)
		-- emptied, it shuts at the next look
		local drained = RobberyUtil.enter(RobberyUtil.new(), robber, ROBBER_TEAM_ID)
		for index, stored in BankDefinition.VAULTS do
			drained = RobberyUtil.press(drained, index)
			for _ = 1, math.ceil(stored / BankDefinition.PAY_AMOUNT) do
				drained, isOver = RobberyUtil.step(drained, 0)
				assert(not isOver, `a bank that still holds something shuts`)
				drained = RobberyUtil.pay(drained, index, { robber })
			end
			assert(drained.Stored[index] == 0, `vault {index} isn't empty after its rounds`)
		end
		drained, isOver = RobberyUtil.step(drained, 0)
		assert(isOver, `an empty bank stays open`)
		-- a shut one is full again + isn't looked at for this
		local shut = RobberyUtil.close(drained)
		shut, isOver = RobberyUtil.step(shut, interval)
		assert(not isOver and shut.Stored[1] == BankDefinition.VAULTS[1], `a shut bank isn't full or shuts again`)
	end),

	-- a pad hands out what its vault holds + no more, to whoever stepped on first, while bank + vault are open
	Pays = SpecUtil.newScenario(function()
		local robber, accomplice, third = newPlayer(), newPlayer(), newPlayer()
		local amount = BankDefinition.PAY_AMOUNT
		local index, stored = 1, BankDefinition.VAULTS[1]
		local state = RobberyUtil.enter(RobberyUtil.new(), robber, ROBBER_TEAM_ID)
		local payments: RobberyUtil.Payments
		local paid: RobberyUtil.State
		paid, payments = RobberyUtil.pay(state, index, { robber })
		assert(paid == state and next(payments) == nil, `a vault that's shut pays`)
		local isOpened: boolean
		state, isOpened = RobberyUtil.press(state, index)
		assert(isOpened and state.IsVaultOpen[index], `its button doesn't open a vault`)
		paid, isOpened = RobberyUtil.press(state, index)
		assert(not isOpened and paid == state, `a button opens a vault twice`)
		assert(not state.IsVaultOpen[index + 1], `a button opens the vault beside its own`)
		-- one robber alone gets all of it, a round at a time
		local alone, total = state, 0
		for _ = 1, stored / amount + 2 do
			alone, payments = RobberyUtil.pay(alone, index, { robber })
			total += payments[robber] or 0
		end
		assert(total == stored and alone.Stored[index] == 0, `one robber is handed {total} of {stored}`)
		-- more of them than a vault has rounds for: the first to step on are paid, the vault never owes
		local last = state
		for _ = 2, stored / amount do
			last = RobberyUtil.pay(last, index, { robber })
		end
		assert(last.Stored[index] == amount, `a vault isn't down to its last round`)
		last, payments = RobberyUtil.pay(last, index, { accomplice, robber, third, accomplice })
		assert(payments[accomplice] == amount, `the first on the pad isn't paid the last round`)
		assert(payments[robber] == nil and payments[third] == nil, `a vault pays more than it holds`)
		assert(last.Stored[index] == 0, `a vault holds {last.Stored[index]} after its last round`)
		-- what couldn't be handed over is back in the vault, which never holds more than it opened with
		local refunded = RobberyUtil.refund(last, index, amount)
		assert(refunded.Stored[index] == amount, `a round that's handed back isn't in the vault`)
		assert(RobberyUtil.refund(state, index, amount).Stored[index] == stored, `a full vault takes more`)
		-- nothing comes out of a bank that's shut, + a robbery that's void leaves it open + shut tight
		local shut = RobberyUtil.close(state)
		shut, payments = RobberyUtil.pay(shut, index, { robber })
		assert(next(payments) == nil and shut.Stored[index] == stored, `a shut bank pays`)
		shut, isOpened = RobberyUtil.press(shut, index)
		assert(not isOpened, `a button opens a vault of a shut bank`)
		local void = RobberyUtil.void(last)
		assert(void.IsOpen and not void.IsVaultOpen[index] and void.Stored[index] == stored, `a void robbery`)
		assert(next(void.Robbers) == nil and not void.IsAlarmed, `a void robbery keeps its list`)
	end),

	-- a shut bank opens in the morning of the city
	Reopens = SpecUtil.newScenario(function()
		local reopenHour = BankDefinition.REOPEN_HOUR
		assert(not RobberyUtil.getIfReopening(reopenHour.Min - 0.01), `it opens before its hour`)
		assert(RobberyUtil.getIfReopening(reopenHour.Min), `it doesn't open on its hour`)
		assert(RobberyUtil.getIfReopening((reopenHour.Min + reopenHour.Max) / 2), `it doesn't open in its hour`)
		assert(not RobberyUtil.getIfReopening(reopenHour.Max), `it opens after its hour`)
		assert(not RobberyUtil.getIfReopening(0), `it opens at midnight`)
	end),

	-- where a beam is follows from the clock alone, + what it went through since the last look holds both ends
	Sweeps = SpecUtil.newScenario(function()
		local pace = BankDefinition.BEAM.Pace
		for _, duration in { 1, 1.75, 2.5, pace.Min, pace.Max } do
			assert(SweepUtil.getAlpha(0, duration) == 0, `a beam of {duration} doesn't start at its end`)
			assert(math.abs(SweepUtil.getAlpha(duration, duration) - 1) < EPSILON, `it isn't across in {duration}`)
			assert(math.abs(SweepUtil.getAlpha(duration * 2, duration)) < EPSILON, `it isn't back in twice that`)
			assert(math.abs(SweepUtil.getAlpha(duration / 4, duration) - 0.25) < EPSILON, `it doesn't go evenly`)
			assert(math.abs(SweepUtil.getAlpha(duration * 1.75, duration) - 0.25) < EPSILON, `it doesn't come back`)
		end
		-- as the old place had a beam: upright, 17.8 studs to go. the clock of a server is a big number
		local turn = CFrame.Angles(0, 0, math.pi / 2)
		local from = CFrame.new(735.66, 171.1, 887) * turn
		local to = CFrame.new(735.66, 171.1, 869.2) * turn
		local size = Vector3.new(18.6, 0.2, 0.2)
		local epoch, duration = 1764000000, 1.4
		for step = 0, 400 do
			local now = epoch + step * 0.013
			local here = SweepUtil.getCFrame(from, to, now, duration)
			assert(here == SweepUtil.getCFrame(from, to, now, duration), `the same clock has it in two places`)
			local alpha = SweepUtil.getAlpha(now, duration)
			assert(alpha >= 0 and alpha <= 1, `it's off its way at step {step}`)
			assert((here.Position - from.Position:Lerp(to.Position, alpha)).Magnitude < 0.001, `it isn't on its way`)
			-- from one look to the next: a frame, a hitch, most of its way + more than there + back
			for _, gap in { 1 / 60, 0.4, duration * 0.9, duration * 3 } do
				local before = now - gap
				local low, high = SweepUtil.getRange(before, now, duration)
				-- wherever it was in between is in the stretch, an end it turned at as well
				for sample = 0, 20 do
					local between = SweepUtil.getAlpha(before + gap * sample / 20, duration)
					assert(between >= low - EPSILON and between <= high + EPSILON, `it was outside of its stretch`)
				end
				local cframe, swept = SweepUtil.getSwept(from, to, size, before, now, duration)
				for _, spot in { here.Position, SweepUtil.getCFrame(from, to, before, duration).Position } do
					local offset = cframe:PointToObjectSpace(spot)
					assert(
						math.abs(offset.X) <= (swept.X - size.X) / 2 + 0.001
							and math.abs(offset.Y) <= (swept.Y - size.Y) / 2 + 0.001
							and math.abs(offset.Z) <= (swept.Z - size.Z) / 2 + 0.001,
						`the box it went through doesn't hold it at a look`
					)
				end
				assert(math.abs(swept.X - size.X) < 0.001, `the box grows along the length of the beam`)
				assert(swept.Magnitude <= (size + Vector3.new(0, 17.8, 17.8)).Magnitude + 0.001, `the box outgrows it`)
			end
		end
		-- there + back takes in the whole way, a look that's no time after the last takes in the beam alone
		local low, high = SweepUtil.getRange(epoch, epoch + duration * 2, duration)
		assert(low == 0 and high == 1, `two turns don't take in the whole way`)
		local _, still = SweepUtil.getSwept(from, to, size, epoch, epoch, duration)
		assert((still - size).Magnitude < 0.001, `a beam that didn't move went through more than itself`)
		-- its pace is rolled in the range of the game
		local random = Random.new(1)
		for _ = 1, 200 do
			local rolled = BankDefinition.rollPace(random)
			assert(rolled >= pace.Min and rolled <= pace.Max, `a pace of {rolled}`)
		end
	end),
}

return Tests
