--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PreyUtil = require("@game/ServerScriptService/Server/Service/Npc/Prey")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local SteerUtil = require("@game/ServerScriptService/Server/Service/Npc/Steer")
-- Types
local NpcType = require("@game/ServerScriptService/Server/Type/Npc")
type TestMap = SimpleTest.TestMap
type Probe = NpcType.Probe
type Memory = SteerUtil.Memory
type Order = SteerUtil.Order
type Sight = SteerUtil.Sight
type Candidate = PreyUtil.Candidate
-- the ray ahead, the same from higher up, or the one down to the floor
type RayKind = "Low" | "High" | "Floor"
-- one ray a wake is to cast, in the order it casts them: which + along which axis, what it's answered, + where it
-- went from once it was cast
type Ray = {
	Kind: RayKind,
	Way: string,
	Sight: Sight?,
	Origin: Vector3?,
	Direction: Vector3?,
}
-- something of a world of boxes, by two of its corners
type Box = {
	Min: Vector3,
	Max: Vector3,
}
-- Constants
-- how the zombie of shl3's old place felt its way, typed off its script by hand: the row of the game is held to it
local PROBE: Probe = table.freeze({
	Length = 7,
	Side = 1,
	Drop = 0.5,
	Lean = 2,
	Rise = 2,
	StepUp = 4.5,
	EdgeAhead = 0.85,
	EdgeDepth = 7,
	Level = 3,
	Stuck = 1,
	Stride = 100,
})
local EPSILON = 0.001
-- where the walker of the rows stands, + prey that's mostly along +x of it
local HERE = Vector3.new(10, 5, 20)
local PREY = HERE + Vector3.new(50, 0, 10)
local X, Z = Vector3.xAxis, Vector3.zAxis
-- the walker of the world of boxes: how far its middle is over the floor, how wide it is, what it walks in a wake
local ROOT_HEIGHT = 3
local BODY_RADIUS = 1
local WAKE_DISTANCE = 7
local WALK_STEP = 0.5
-- Variables
-- References
-- Private Functions
local function getIfNear(position: Vector3, other: Vector3): boolean
	return (position - other).Magnitude < EPSILON
end

local function getWay(direction: Vector3): string
	if math.abs(direction.X) > math.abs(direction.Z) then
		return if direction.X > 0 then "+X" else "-X"
	end
	return if direction.Z > 0 then "+Z" else "-Z"
end

local function newRay(kind: RayKind, way: string, sight: Sight?): Ray
	return {
		Kind = kind,
		Way = way,
		Sight = sight,
	}
end

local function newMemory(
	mode: SteerUtil.Mode,
	heading: Vector3,
	saved: Vector3,
	last: Vector3?,
	isClimbing: boolean?
): Memory
	local memory: Memory = {
		Mode = mode,
		Heading = heading,
		Saved = saved,
		Last = last,
		Goal = HERE,
		IsClimbing = isClimbing == true,
	}
	return table.freeze(memory)
end

-- one wake of a walker that's answered ray by ray. a ray it wasn't to cast, or one it was + didn't, lets the row down
local function wake(memory: Memory, position: Vector3, prey: Vector3?, rays: { Ray }): (Memory, Order)
	local count = 0
	local nextMemory, order = SteerUtil.step(memory, {
		Position = position,
		Prey = prey,
		Cast = function(origin: Vector3, direction: Vector3): Sight?
			count += 1
			local ray = rays[count]
			assert(ray, `it casts more than the {#rays} rays it's to`)
			local kind: RayKind, way: string
			if direction.X == 0 and direction.Z == 0 then
				kind, way = "Floor", getWay(origin - position)
			else
				kind, way = if origin.Y > position.Y then "High" else "Low", getWay(direction)
			end
			assert(kind == ray.Kind and way == ray.Way, `ray {count} is {kind} {way}, not {ray.Kind} {ray.Way}`)
			ray.Origin, ray.Direction = origin, direction
			return ray.Sight
		end,
	}, PROBE)
	assert(count == #rays, `it casts {count} of the {#rays} rays it's to`)
	return nextMemory, order
end

-- a row of the table the steering was written to: whatever lets it down says which
local function row(index: number, fn: () -> ())
	local isOk, problem = pcall(fn :: any)
	if not isOk then
		error(`row {index}: {problem}`, 0)
	end
end

-- how far along a ray it runs into a box, as a share of the ray. nil if it doesn't
local function getHit(box: Box, origin: Vector3, direction: Vector3): number?
	local near, far = 0, 1
	for _, axis in { "X", "Y", "Z" } do
		local start, step = (origin :: any)[axis], (direction :: any)[axis]
		local min, max = (box.Min :: any)[axis], (box.Max :: any)[axis]
		if step == 0 then
			if start < min or start > max then
				return nil
			end
		else
			local enter, leave = (min - start) / step, (max - start) / step
			if enter > leave then
				enter, leave = leave, enter
			end
			near, far = math.max(near, enter), math.min(far, leave)
			if near > far then
				return nil
			end
		end
	end
	return near
end

-- the top of the floor under a spot, nil over nothing
local function getFloor(boxes: { Box }, position: Vector3): number?
	local floor: number? = nil
	for _, box in boxes do
		local isOver = position.X >= box.Min.X
			and position.X <= box.Max.X
			and position.Z >= box.Min.Z
			and position.Z <= box.Max.Z
		if isOver and box.Max.Y <= position.Y - ROOT_HEIGHT + EPSILON and (not floor or box.Max.Y > floor) then
			floor = box.Max.Y
		end
	end
	return floor
end

-- if a body can't stand there: something that isn't under its feet is closer than it's wide
local function getIfInside(boxes: { Box }, position: Vector3): boolean
	for _, box in boxes do
		local isBeside = box.Max.Y > position.Y - ROOT_HEIGHT + 1 and box.Min.Y < position.Y + 1
		local isClose = position.X > box.Min.X - BODY_RADIUS
			and position.X < box.Max.X + BODY_RADIUS
			and position.Z > box.Min.Z - BODY_RADIUS
			and position.Z < box.Max.Z + BODY_RADIUS
		if isBeside and isClose then
			return true
		end
	end
	return false
end

-- walks a body through a world of boxes, one wake after the other: it's steered by what the rays find of the boxes,
-- gets as far towards its goal as nothing is in the way of, + comes down on whatever floor is under it. a jump lifts
-- nothing in here. answers every spot it woke at + the one it ended up at, + how often it was told to jump
local function walk(boxes: { Box }, start: Vector3, prey: Vector3, wakeCount: number): ({ Vector3 }, number)
	local position = start
	local memory = SteerUtil.new(start)
	local positions: { Vector3 } = {}
	local jumpCount = 0
	for _ = 1, wakeCount do
		table.insert(positions, position)
		local order: Order
		memory, order = SteerUtil.step(memory, {
			Position = position,
			Prey = prey,
			Cast = function(origin: Vector3, direction: Vector3): Sight?
				for _, box in boxes do
					if getHit(box, origin, direction) then
						return "Solid"
					end
				end
				return nil
			end,
		}, PROBE)
		if order.IsJumping then
			jumpCount += 1
		end
		local gap = Vector3.new(order.Goal.X - position.X, 0, order.Goal.Z - position.Z)
		local distance = math.min(gap.Magnitude, WAKE_DISTANCE)
		for _ = 1, math.floor(distance / WALK_STEP) do
			local nextPosition = position + gap.Unit * WALK_STEP
			if getIfInside(boxes, nextPosition) then
				break
			end
			local floor = getFloor(boxes, nextPosition)
			assert(floor, `it walks off the world at {nextPosition}`)
			position = Vector3.new(nextPosition.X, floor + ROOT_HEIGHT, nextPosition.Z)
		end
	end
	table.insert(positions, position)
	return positions, jumpCount
end

-- how close a walk ever got to a spot
local function getNearest(positions: { Vector3 }, target: Vector3): number
	local nearest = math.huge
	for _, position in positions do
		nearest = math.min(nearest, (position - target).Magnitude)
	end
	return nearest
end

local function newCandidate(position: Vector3, teamId: "Heroes" | "Villains" | nil): Candidate
	return {
		Position = position,
		TeamId = teamId,
		IsAlive = true,
		IsSheltered = false,
	}
end
-- Class
local Tests: TestMap = {
	-- every turn of the steering, a wake to a row: what it kept + what it sees in, what it does + keeps out
	Steer = SpecUtil.newScenario(function()
		local fresh = SteerUtil.new(HERE)
		local moved = HERE - X * 7

		row(1, function()
			local memory, order = wake(fresh, HERE, nil, {})
			assert(order.Goal == HERE and not order.IsFollowing and not order.IsJumping, `it doesn't stand`)
			assert(memory.Mode == "Seek", `it's on a detour`)
		end)

		row(2, function()
			local floor = newRay("Floor", "+X", "Solid")
			local memory, order = wake(fresh, HERE, HERE + X * 50, { newRay("Low", "+X", nil), floor })
			assert(order.Goal == HERE + X * 50 and order.IsFollowing and not order.IsJumping, `it isn't after its prey`)
			assert(memory.Mode == "Seek" and memory.Last == HERE, `it's on a detour, or forgot where it stood`)
			-- the floor is asked for most of a ray ahead of it, a ray down
			assert(
				floor.Origin and getIfNear(floor.Origin, HERE + X * 5.95),
				`the floor is asked for at {floor.Origin}`
			)
			assert(floor.Direction == Vector3.new(0, -7, 0), `the floor is asked for {floor.Direction} down`)
		end)

		row(3, function()
			local rays = { newRay("Low", "+X", "Solid"), newRay("High", "+X", nil) }
			local memory, order = wake(fresh, HERE, PREY, rays)
			assert(order.IsJumping and order.Goal == PREY and order.IsFollowing, `it doesn't jump at its prey`)
			assert(memory.Mode == "Seek", `it's on a detour`)
		end)

		row(4, function()
			local memory, order = wake(fresh, HERE, PREY, {
				newRay("Low", "+X", "Solid"),
				newRay("High", "+X", "Solid"),
				newRay("Low", "+X", nil),
				newRay("Floor", "+X", "Solid"),
			})
			assert(order.Goal == HERE + X * 100 and not order.IsFollowing, `it isn't sent 100 studs along +x`)
			assert(not order.IsJumping, `it jumps`)
			assert(memory.Mode == "Seek" and memory.Heading == X and memory.Saved == X, `the way it saved isn't free`)
		end)

		row(5, function()
			local memory, order = wake(fresh, HERE, PREY, {
				newRay("Low", "+X", "Solid"),
				newRay("High", "+X", "Solid"),
				newRay("Low", "+X", "Solid"),
				newRay("High", "+X", "Solid"),
				newRay("Low", "-Z", nil),
				newRay("Floor", "-Z", "Solid"),
			})
			assert(memory.Mode == "Detour" and memory.Heading == -Z and memory.Saved == X, `it didn't turn left once`)
			assert(order.Goal == HERE - Z * 100 and not order.IsFollowing, `it isn't sent 100 studs along -z`)
		end)

		row(6, function()
			local memory, order = wake(newMemory("Detour", -Z, X, moved), HERE, PREY, {
				newRay("Low", "+X", nil),
				newRay("Floor", "+X", "Solid"),
			})
			assert(memory.Mode == "Seek" and memory.Heading == X, `it isn't back to seeking along the way it saved`)
			assert(order.Goal == HERE + X * 100 and not order.IsFollowing, `it isn't sent 100 studs along +x`)
		end)

		row(7, function()
			local rays: { Ray } = {}
			for _, way in { "+X", "-Z", "-X", "+Z" } do
				table.insert(rays, newRay("Low", way, "Solid"))
				table.insert(rays, newRay("High", way, "Solid"))
			end
			local memory, order = wake(newMemory("Detour", -Z, X, moved), HERE, PREY, rays)
			assert(order.IsJumping, `shut in on four sides it doesn't jump`)
			assert(memory.Mode == "Detour" and memory.Heading == Z, `its heading isn't three left turns on`)
			assert(order.Goal == HERE + Z * 100 and not order.IsFollowing, `it isn't sent along its heading`)
		end)

		row(8, function()
			local memory, order = wake(newMemory("Seek", X, X, HERE), HERE, PREY, {
				newRay("Low", "+X", nil),
				newRay("Floor", "+X", "Solid"),
				newRay("Low", "-Z", nil),
				newRay("Floor", "-Z", "Solid"),
			})
			assert(memory.Mode == "Detour" and memory.Saved == X, `stuck with nothing in the way it seeks on`)
			assert(memory.Heading == -Z and order.Goal == HERE - Z * 100, `it didn't turn left before it looked`)
			assert(not order.IsFollowing and not order.IsJumping, `it follows or jumps`)
		end)

		row(9, function()
			local memory, order = wake(fresh, HERE, PREY, { newRay("Low", "+X", "Prey") })
			assert(memory.Mode == "Seek" and memory.IsClimbing, `its prey is in its way, or it isn't climbing`)
			assert(order.Goal == PREY and order.IsFollowing and not order.IsJumping, `it isn't after its prey`)
		end)

		row(10, function()
			local memory, order = wake(fresh, HERE, PREY - Vector3.yAxis * 2.9, { newRay("Low", "+X", "Truss") })
			assert(memory.Mode == "Seek" and memory.IsClimbing, `a truss is in its way, or it isn't climbing`)
			assert(order.IsFollowing and not order.IsJumping, `it isn't after its prey`)
			-- with its prey further down a truss is anything else: jumped where the ray from higher up clears it
			memory, order = wake(fresh, HERE, PREY - Vector3.yAxis * 3.1, {
				newRay("Low", "+X", "Truss"),
				newRay("High", "+X", nil),
			})
			assert(memory.Mode == "Seek" and not memory.IsClimbing and order.IsJumping, `it climbs down after it`)
		end)

		row(11, function()
			local memory, order = wake(fresh, HERE, PREY, { newRay("Low", "+X", "Terrain") })
			assert(memory.Mode == "Seek" and not memory.IsClimbing, `the terrain is in its way`)
			assert(order.Goal == PREY and order.IsFollowing and not order.IsJumping, `it isn't after its prey`)
		end)

		row(12, function()
			-- another walker ahead, by where the heading it has left over leads: along +x it's nothing
			local memory, order = wake(newMemory("Seek", X, X, moved), HERE, PREY, {
				newRay("Low", "+X", "Kin"),
				newRay("Floor", "+X", "Solid"),
			})
			assert(memory.Mode == "Seek" and order.IsFollowing and not order.IsJumping, `it isn't walked through`)
			-- along z it's a wall, which sets it off along +x: there it's nothing again
			memory, order = wake(newMemory("Seek", Z, X, moved), HERE, PREY, {
				newRay("Low", "+X", "Kin"),
				newRay("Low", "+X", "Kin"),
				newRay("Floor", "+X", "Solid"),
			})
			assert(order.Goal == HERE + X * 100 and not order.IsFollowing, `it isn't a wall`)
			-- along -x it's whatever else is in the way
			memory, order = wake(newMemory("Seek", -X, X, moved), HERE, PREY, {
				newRay("Low", "+X", "Kin"),
				newRay("High", "+X", nil),
			})
			assert(memory.Mode == "Seek" and order.IsFollowing and order.IsJumping, `it isn't jumped`)
		end)

		row(13, function()
			local memory, order = wake(fresh, HERE, PREY, {
				newRay("Low", "+X", nil),
				newRay("Floor", "+X", nil),
				newRay("Low", "+X", nil),
				newRay("Floor", "+X", nil),
				newRay("Low", "-Z", nil),
				newRay("Floor", "-Z", "Solid"),
			})
			assert(memory.Mode == "Detour" and memory.Heading == -Z, `an edge isn't gone along`)
			assert(order.Goal == HERE - Z * 100 and not order.IsFollowing, `it isn't sent along the edge`)
		end)

		row(14, function()
			-- the floor isn't asked for
			local memory, order = wake(fresh, HERE, PREY - Vector3.yAxis * 3.1, { newRay("Low", "+X", nil) })
			assert(memory.Mode == "Seek" and order.IsFollowing, `it doesn't walk off after its prey`)
		end)

		row(15, function()
			local sought = table.clone(newMemory("Seek", X, X, moved))
			sought.Goal = PREY
			local memory, order = wake(table.freeze(sought), HERE, nil, {})
			assert(order.Goal == PREY and not order.IsFollowing and not order.IsJumping, `it's sent somewhere new`)
			assert(memory.Mode == "Seek" and memory.Last == nil, `it keeps where it stood`)
			-- the way round something is dropped where it stands
			memory, order = wake(newMemory("Detour", -Z, X, moved), HERE + X, nil, {})
			assert(memory.Mode == "Seek" and order.Goal == HERE + X and not order.IsFollowing, `it carries on round`)
		end)

		row(16, function()
			local memory, order = wake(newMemory("Detour", -Z, X, moved, true), HERE, PREY + Vector3.yAxis * 3, {
				newRay("Low", "-Z", nil),
				newRay("Floor", "-Z", "Solid"),
			})
			assert(memory.Mode == "Detour" and memory.Heading == -Z, `it turned`)
			assert(order.Goal == HERE - Z * 100, `it isn't sent along its heading`)
			-- with its prey not as far over it, it turns right as ever
			local turned = wake(newMemory("Detour", -Z, X, moved, true), HERE, PREY + Vector3.yAxis * 2.9, {
				newRay("Low", "+X", nil),
				newRay("Floor", "+X", "Solid"),
			})
			assert(turned.Mode == "Seek" and turned.Heading == X, `it didn't turn right`)
		end)

		row(17, function()
			local low, high = newRay("Low", "+Z", "Solid"), newRay("High", "+Z", nil)
			wake(SteerUtil.new(Vector3.zero), Vector3.zero, Z * 50, { low, high })
			local direction = Vector3.new(2, 2, 7).Unit * 7
			assert(low.Origin and getIfNear(low.Origin, Vector3.new(-1, -0.5, 0)), `the ray leaves from {low.Origin}`)
			assert(low.Direction and getIfNear(low.Direction, direction), `the ray goes {low.Direction}`)
			assert(
				high.Origin and getIfNear(high.Origin, Vector3.new(-1, 4, 0)),
				`the high ray leaves from {high.Origin}`
			)
			assert(high.Direction and getIfNear(high.Direction, direction), `the high ray goes {high.Direction}`)
		end)
	end),

	-- the steering let loose in a world of boxes: it knows no path, so these are the ways it's known to find
	Course = SpecUtil.newScenario(function()
		local ground: Box = { Min = Vector3.new(-100, -1, -100), Max = Vector3.new(200, 0, 100) }
		local start = Vector3.new(0, ROOT_HEIGHT, 0)
		local prey = Vector3.new(80, ROOT_HEIGHT, 0)

		-- a wall across its way with one gap in it, off to the side a detour leads along first
		local positions = walk({
			ground,
			{ Min = Vector3.new(30, 0, -100), Max = Vector3.new(32, 20, -30) },
			{ Min = Vector3.new(30, 0, -18), Max = Vector3.new(32, 20, 100) },
		}, start, prey, 200)
		local nearest = getNearest(positions, prey)
		assert(nearest < WAKE_DISTANCE, `it gets no closer than {nearest} studs to prey behind a wall with a gap`)

		-- walls on all four sides, each within reach of its ray from anywhere between them
		local cell: { Box } = {
			ground,
			{ Min = Vector3.new(3, 0, -5), Max = Vector3.new(5, 20, 5) },
			{ Min = Vector3.new(-5, 0, -5), Max = Vector3.new(-3, 20, 5) },
			{ Min = Vector3.new(-5, 0, 3), Max = Vector3.new(5, 20, 5) },
			{ Min = Vector3.new(-5, 0, -5), Max = Vector3.new(5, 20, -3) },
		}
		local jumpCount: number
		positions, jumpCount = walk(cell, start, prey, 200)
		assert(jumpCount == 200, `shut in for 200 wakes it jumps at {jumpCount} of them`)
		for _, position in positions do
			assert(math.abs(position.X) < 3 and math.abs(position.Z) < 3, `it gets out to {position}`)
		end

		-- prey on the floor below: the edge isn't a wall
		local floors: { Box } = {
			{ Min = Vector3.new(-100, -1, -400), Max = Vector3.new(200, 0, 400) },
			{ Min = Vector3.new(-50, 0, -400), Max = Vector3.new(0, 20, 400) },
		}
		local ledge = Vector3.new(-18, 20 + ROOT_HEIGHT, 0)
		positions = walk(floors, ledge, prey, 30)
		assert(getNearest(positions, prey) < WAKE_DISTANCE, `it doesn't get to prey that's a floor below`)
		-- with the prey up there with it the same edge keeps it: it goes along it
		positions = walk(floors, ledge, prey + Vector3.yAxis * 20, 30)
		for _, position in positions do
			assert(position.Y == ledge.Y, `it walks off an edge after prey that's level with it`)
		end
		assert((positions[#positions] - ledge).Magnitude > 100, `it stands at the edge`)
	end),

	-- who it goes after
	Prey = SpecUtil.newScenario(function()
		local here = Vector3.new(100, 4, -50)
		local function at(distance: number): Vector3
			return here + Vector3.new(0, 0, distance)
		end
		assert(PreyUtil.pick(here, {}, 600, "Heroes") == nil, `it hunts with nobody there`)
		local heroes =
			{ newCandidate(at(300), "Heroes"), newCandidate(at(-120), "Heroes"), newCandidate(at(200), "Heroes") }
		assert(PreyUtil.pick(here, heroes, 600, "Heroes") == 2, `it isn't after the nearest of three`)
		-- as far as it sees + not a stud further
		assert(PreyUtil.pick(here, { newCandidate(at(599), "Heroes") }, 600, "Heroes") == 1, `it doesn't see 599 studs`)
		assert(PreyUtil.pick(here, { newCandidate(at(601), "Heroes") }, 600, "Heroes") == nil, `it sees 601 studs`)
		-- it walks past the other side, + past whoever wears none
		local mixed = { newCandidate(at(10), "Villains"), newCandidate(at(20), nil), newCandidate(at(400), "Heroes") }
		assert(PreyUtil.pick(here, mixed, 600, "Heroes") == 3, `it isn't after the hero`)
		assert(PreyUtil.pick(here, { mixed[1], mixed[2] }, 600, "Heroes") == nil, `it hunts a villain`)
		-- one that's down or that the rule shelters isn't hunted, the next one is
		local down = newCandidate(at(10), "Heroes")
		down.IsAlive = false
		local sheltered = newCandidate(at(20), "Heroes")
		sheltered.IsSheltered = true
		assert(PreyUtil.pick(here, { down, sheltered, heroes[1] }, 600, "Heroes") == 3, `it isn't after the one left`)
		assert(PreyUtil.pick(here, { down, sheltered }, 600, "Heroes") == nil, `it hunts somebody it's to leave alone`)
	end),

	-- the zombie of the game is the one of its old place, number for number
	Row = SpecUtil.newScenario(function()
		-- the bodies of another game are never required, + neither is a module that raises there
		local NpcDefinition = require("@game/ServerScriptService/Server/Definition/Npc")
		local npcRes = NpcDefinition.get("zombie")
		assert(npcRes.IsOk, `the game has no zombie`)
		local npc = npcRes.Value
		assert(SpecUtil.getIfEqual(npc.Probe, PROBE), `it doesn't feel its way as its old place had it`)
		assert(npc.MaxHealth == 40 and npc.WalkSpeed == 20 and npc.Sight == 600, `its health, speed or sight is off`)
		assert(math.abs(npc.WakeDistance / npc.WalkSpeed - 0.35) < EPSILON, `it doesn't wake every 0.35 s`)
		assert(npc.StartDelay.Min == 1 and npc.StartDelay.Max == 2, `it doesn't start 1 to 2 s in`)
		assert(npc.PreyTeamId == "Heroes", `it isn't after the heroes`)
		assert(npc.Damage == 15 and npc.DamageCooldown == 1.5 and npc.ArmPattern == "Arm", `its touch is off`)
		assert(npc.Regeneration.Fraction == 0.01 and npc.Regeneration.Interval == 1, `what it gets back is off`)
		assert(npc.RemoveDelay == 1.5, `it doesn't lie for a second + a half`)
		assert(NpcDefinition.MAX_COUNT == 18, `a wave isn't 18`)
		assert(NpcDefinition.get("ghoul").IsErr, `the game has a body nobody listed`)
	end),
}

-- only a game with bodies nobody plays has anything to hold this to
return if GameDefinition.FEATURES.Npcs then Tests else {} :: TestMap
