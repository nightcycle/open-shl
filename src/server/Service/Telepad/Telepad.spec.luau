--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local RideUtil = require("@game/ServerScriptService/Server/Service/Telepad/Ride")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
type End = RideUtil.End<string>
-- Constants
-- the pads of the city of shl3, by the ids its map marks them with
local PAD_COUNTS: { [string]: number } = table.freeze({ hospital = 4, news = 8, syndicorp = 4 })
local IDS: { string } = {}
for building, count in PAD_COUNTS do
	for index = 1, count do
		table.insert(IDS, `{building}-{index}`)
	end
end
table.freeze(IDS)
-- set down right at the exit, + the way the elevators of shl1 do it
local EXACT: RideUtil.Landing = table.freeze({
	Rise = table.freeze({ Min = 0, Max = 0 }),
	Spread = 0,
	Facing = "Exit" :: RideUtil.Facing,
})
local LOOSE: RideUtil.Landing = table.freeze({
	Rise = table.freeze({ Min = 2, Max = 3 }),
	Spread = 1,
	Facing = "Center" :: RideUtil.Facing,
})
-- Variables
-- References
-- Private Functions
-- a part of the map is only ever told apart from another, so its name stands in for it
local function newEnds(prefix: string, ids: { string }): { End }
	local ends: { End } = {}
	for _, id in ids do
		table.insert(ends, { Part = `{prefix} {id}`, Id = id })
	end
	return ends
end

local function getCount(exits: { [string]: string }): number
	local count = 0
	for _ in exits do
		count += 1
	end
	return count
end
-- Class
local Tests: TestMap = {
	-- every pad leads to the exit of its own id, + a map that's spelt wrong says where
	Pair = SpecUtil.newScenario(function()
		local pairing = RideUtil.pair(newEnds("pad", IDS), newEnds("exit", IDS))
		assert(getCount(pairing.Exits) == 16, `16 pads lead to {getCount(pairing.Exits)} exits`)
		assert(#pairing.Faults == 0 and #pairing.Notes == 0, `a map that's right has something wrong with it`)
		for _, id in IDS do
			assert(pairing.Exits[`pad {id}`] == `exit {id}`, `the pad "{id}" leads to {pairing.Exits[`pad {id}`]}`)
		end

		-- two pads may share an exit
		local shared = RideUtil.pair(newEnds("pad", { "a", "a" }), newEnds("exit", { "a" }))
		assert(#shared.Faults == 0 and #shared.Notes == 0, `two pads can't share an exit`)

		local lost = RideUtil.pair(newEnds("pad", { "a", "b" }), newEnds("exit", { "a" }))
		assert(lost.Exits["pad a"] == "exit a", `a pad that's right is taken down with one that isn't`)
		assert(lost.Exits["pad b"] == nil, `a pad without an exit leads somewhere`)
		assert(#lost.Faults == 1 and string.find(lost.Faults[1], '"b"', 1, true), `the pad isn't named`)

		local doubled = RideUtil.pair(newEnds("pad", { "a", "b" }), newEnds("exit", { "a", "b", "a", "a" }))
		assert(doubled.Exits["pad a"] == nil, `a pad with two exits leads to one of them`)
		assert(doubled.Exits["pad b"] == "exit b", `a pad that's right is taken down with one that isn't`)
		assert(#doubled.Faults == 1 and string.find(doubled.Faults[1], '"a"', 1, true), `the exits aren't named once`)

		local idle = RideUtil.pair(newEnds("pad", { "a" }), newEnds("exit", { "a", "c" }))
		assert(idle.Exits["pad a"] == "exit a" and #idle.Faults == 0, `an exit nobody is led to is a fault`)
		assert(#idle.Notes == 1 and string.find(idle.Notes[1], '"c"', 1, true), `the exit isn't named`)
	end),

	-- a pad carries whoever neither wait is running for
	Ready = SpecUtil.newScenario(function()
		assert(RideUtil.getIfReady(10, nil, nil), `a pad that never carried anybody doesn't`)
		assert(RideUtil.getIfReady(10, 10, 10), `a wait that's just over isn't`)
		assert(RideUtil.getIfReady(10, 4, nil) and RideUtil.getIfReady(10, nil, 4), `a wait that's long over isn't`)
		assert(not RideUtil.getIfReady(10, 10.1, nil), `a pad that's shut carries somebody`)
		assert(not RideUtil.getIfReady(10, nil, 10.1), `whoever just arrived is carried`)
		assert(not RideUtil.getIfReady(10, 4, 13), `the wait of the pad being over ends the rider's`)
	end),

	-- where they're set down: right at the exit, or anywhere in the box over it
	Landing = SpecUtil.newScenario(function()
		local random = Random.new(1)
		local exit = CFrame.new(1156.3, 956.4, 806.8) * CFrame.Angles(0, 2.1, 0)
		for _ = 1, 20 do
			assert(RideUtil.getLanding(exit, EXACT, random) == exit, `it isn't the exit to the stud`)
		end

		local landing = CFrame.new(-93.8, 104.07, 45.8)
		local isSeen: { [string]: true } = {}
		for _ = 1, 200 do
			local target = RideUtil.getLanding(landing, LOOSE, random)
			local offset = target.Position - landing.Position
			assert(math.abs(offset.X) <= 1.001 and math.abs(offset.Z) <= 1.001, `{offset} is off to a side`)
			assert(offset.Y >= 1.999 and offset.Y <= 3.001, `{offset} isn't 2 to 3 studs up`)
			isSeen[`{math.round(offset.X)} {math.round(offset.Y)} {math.round(offset.Z)}`] = true
			-- level, + turned to the line straight up through the middle of the map
			local toCenter = (Vector3.new(0, target.Y, 0) - target.Position).Unit
			assert(math.abs(target.LookVector.Y) < 0.001, `it's tipped`)
			assert(target.LookVector:Dot(toCenter) > 0.999, `it doesn't look to the middle`)
		end
		local count = 0
		for _ in isSeen do
			count += 1
		end
		assert(count == 18, `{count} of the 18 spots of the box were landed on`)
	end),
}

-- only a game with pads has anything to hold this to
return if GameDefinition.FEATURES.Telepads then Tests else {} :: TestMap
