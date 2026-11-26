--!strict
-- Services
-- Packages
-- Modules
-- Types
local NpcType = require("@game/ServerScriptService/Server/Type/Npc")
type Probe = NpcType.Probe
-- it walks at its prey, or along something that's in the way of that
export type Mode = "Seek" | "Detour"
-- what a walker keeps from one wake to the next
export type Memory = {
	Mode: Mode,
	-- the way a detour leads: one of the four ways along the level axes of the map, a stud long
	Heading: Vector3,
	-- the heading the detour set out on, it's over once that way is free again
	Saved: Vector3,
	-- where it stood at its last wake. nil where that tells nothing: it just came in, or it had nobody to go after
	Last: Vector3?,
	Goal: Vector3,
	-- the last thing its ray ran into was its prey or something it climbs
	IsClimbing: boolean,
}
-- what a ray ran into: the body it's after, another walker, something to climb, the ground of the engine, or anything
-- else there is
export type Sight = "Prey" | "Kin" | "Truss" | "Terrain" | "Solid"
export type Senses = {
	Position: Vector3,
	-- where the nearest it may hunt is, nil with none in sight
	Prey: Vector3?,
	-- what a ray of that length runs into first, the walker itself aside
	Cast: (origin: Vector3, direction: Vector3) -> Sight?,
}
-- what it does until the next wake
export type Order = {
	Goal: Vector3,
	-- the goal is its prey, wherever that gets to meanwhile
	IsFollowing: boolean,
	IsJumping: boolean,
}
-- Constants
-- the way the engine has a spot look at itself
local DEFAULT_FORWARD = -Vector3.zAxis
-- Variables
-- References
-- Private Functions
-- a quarter to its right + to its left, seen from above
local function turnRight(heading: Vector3): Vector3
	return Vector3.new(-heading.Z, 0, heading.X)
end

local function turnLeft(heading: Vector3): Vector3
	return Vector3.new(heading.Z, 0, -heading.X)
end

-- what's in the way of a level step that way. answers if it's blocked, if it takes a jump + if it's a climb
local function look(
	senses: Senses,
	prey: Vector3,
	heading: Vector3,
	forward: Vector3,
	probe: Probe
): (boolean, boolean, boolean)
	local position = senses.Position
	local right = forward:Cross(Vector3.yAxis)
	-- from its right shoulder to ahead of its left one, rising: a kerb is under it + a doorway isn't
	local origin = position + right * probe.Side - Vector3.new(0, probe.Drop, 0)
	local direction = (forward * probe.Length - right * probe.Lean + Vector3.new(0, probe.Rise, 0)).Unit * probe.Length
	local sight = senses.Cast(origin, direction)
	-- another walker is nothing, a wall or something to get over by where its own last detour happened to lead: its
	-- old place had it so, the heading is read while it seeks as well
	if sight == "Kin" then
		if heading.X > 0 then
			sight = nil
		elseif heading.X == 0 then
			return true, false, false
		end
	end
	-- prey that's lower than a level under it isn't climbed after
	local isLevel = prey.Y > position.Y - probe.Level
	if sight == "Prey" or (sight == "Truss" and isLevel) then
		return false, false, true
	elseif sight == "Terrain" then
		return false, false, false
	elseif sight ~= nil then
		-- what the same ray clears from higher up is low enough to jump
		if senses.Cast(origin + Vector3.new(0, probe.StepUp, 0), direction) == nil then
			return false, true, false
		end
		return true, false, false
	end
	-- nothing ahead: an edge is a wall, unless the prey is down there
	if isLevel then
		local ahead = position + forward * probe.Length * probe.EdgeAhead
		return senses.Cast(ahead, Vector3.new(0, -probe.EdgeDepth, 0)) == nil, false, false
	end
	return false, false, false
end
-- Class
-- how a walker finds its way, one wake at a time: straight at its prey; what's low + in the way is jumped; a wall is
-- followed with the right hand along the axes of the map until the way it first took is free again; an edge is a wall
-- unless the prey is below. it knows no path + keeps nothing of the map. nothing in here touches the engine: what it
-- sees comes in as data + what it does goes out as data, so every turn of it can be held to a table
local Module = {}

Module.new = function(position: Vector3): Memory
	local memory: Memory = {
		Mode = "Seek",
		Heading = Vector3.xAxis,
		Saved = Vector3.xAxis,
		Last = nil,
		Goal = position,
		IsClimbing = false,
	}
	return table.freeze(memory)
end

-- one wake: what it keeps from here on + what it's to do until the next
Module.step = function(memory: Memory, senses: Senses, probe: Probe): (Memory, Order)
	local position = senses.Position
	local prey = senses.Prey
	local mode: Mode, heading, saved = memory.Mode, memory.Heading, memory.Saved
	local goal, isClimbing = memory.Goal, memory.IsClimbing
	local isStuck = memory.Last ~= nil and (position - memory.Last).Magnitude < probe.Stuck
	local isFollowing, isJumping = false, false

	if not prey then
		-- nobody to hunt: it ends up where it last was after somebody + stands. the way round something leads
		-- nowhere without anybody behind it, so that's dropped where it is
		if mode == "Detour" then
			mode = "Seek"
			goal = position
		end
		if isStuck then
			heading = turnLeft(heading)
		end
		local idleMemory: Memory = {
			Mode = mode,
			Heading = heading,
			Saved = saved,
			Last = nil,
			Goal = goal,
			IsClimbing = isClimbing,
		}
		local idleOrder: Order = {
			Goal = goal,
			IsFollowing = false,
			IsJumping = false,
		}
		return table.freeze(idleMemory), table.freeze(idleOrder)
	end

	if mode == "Seek" then
		goal = prey
		isFollowing = true
		local gap = prey - position
		local level = Vector3.new(gap.X, 0, gap.Z)
		local forward = if level.Magnitude > 0 then level.Unit else DEFAULT_FORWARD
		local isBlocked, isJump, isClimb = look(senses, prey, heading, forward, probe)
		isJumping, isClimbing = isJump, isClimb
		if isBlocked or isStuck then
			-- round it along the axis the prey is further off on
			if math.abs(gap.X) > math.abs(gap.Z) then
				heading = if gap.X < 0 then -Vector3.xAxis else Vector3.xAxis
			else
				heading = if gap.Z < 0 then -Vector3.zAxis else Vector3.zAxis
			end
			saved = heading
			mode = "Detour"
		end
	elseif not isStuck and (not isClimbing or prey.Y < position.Y + probe.Level) then
		-- it got somewhere along the wall, so it tries the side the wall is on again
		heading = turnRight(heading)
	end
	if isStuck then
		heading = turnLeft(heading)
	end
	if mode == "Detour" then
		local turnCount = 0
		while true do
			local isBlocked, isJump, isClimb = look(senses, prey, heading, heading, probe)
			isJumping, isClimbing = isJumping or isJump, isClimb
			if not isBlocked then
				-- the first way it tried is free + it's the one it set out on: nothing is in the way any more
				if turnCount == 0 and heading == saved then
					mode = "Seek"
				end
				break
			end
			-- shut in on all four sides
			if turnCount == 3 then
				isJumping = true
				break
			end
			heading = turnLeft(heading)
			turnCount += 1
		end
		-- a spot of the world: its old place sent this one off from wherever the prey stood on the wake a detour began
		goal = position + heading * probe.Stride
		isFollowing = false
	end

	local newMemory: Memory = {
		Mode = mode,
		Heading = heading,
		Saved = saved,
		Last = position,
		Goal = goal,
		IsClimbing = isClimbing,
	}
	local order: Order = {
		Goal = goal,
		IsFollowing = isFollowing,
		IsJumping = isJumping,
	}
	return table.freeze(newMemory), table.freeze(order)
end

return Module
