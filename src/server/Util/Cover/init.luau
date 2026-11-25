--!strict
-- Services
-- Packages
-- Modules
local BodyUtil = require("@game/ReplicatedStorage/Shared/Util/Body")
-- Types
-- Constants
-- Variables
-- the covers that are up, each with the character that carries it
local Owners: { [BasePart]: Model } = {}
-- References
-- Private Functions
-- the stretch of a way that's between the two faces a box has along one axis, as shares of the way: where it gets
-- between them + where it's out again. one that runs along the faces is between them all the way or never
local function getSpan(position: number, pace: number, halfSize: number): (number, number)
	if pace == 0 then
		if math.abs(position) > halfSize then
			return math.huge, -math.huge
		end
		return -math.huge, math.huge
	end
	local nearAlpha, farAlpha = (-halfSize - position) / pace, (halfSize - position) / pace
	return math.min(nearAlpha, farAlpha), math.max(nearAlpha, farAlpha)
end

-- if the way from one spot to another goes into the box of a part: a slab test in the part's own space, with nothing
-- to spare. a way that starts inside the box doesn't go into it, as a ray that starts inside a part doesn't find it
local function getIfCrossed(part: BasePart, origin: Vector3, goal: Vector3): boolean
	local cframe = part.CFrame
	local halfSize = part.Size / 2
	local start = cframe:PointToObjectSpace(origin)
	local step = cframe:PointToObjectSpace(goal) - start
	local enterX, leaveX = getSpan(start.X, step.X, halfSize.X)
	local enterY, leaveY = getSpan(start.Y, step.Y, halfSize.Y)
	local enterZ, leaveZ = getSpan(start.Z, step.Z, halfSize.Z)
	local enterAlpha = math.max(enterX, enterY, enterZ)
	local leaveAlpha = math.min(leaveX, leaveY, leaveZ)
	return enterAlpha <= leaveAlpha and enterAlpha > 0 and enterAlpha <= 1
end
-- Class
-- the server's count of what characters carry between themselves + a hit: a shield, the ice somebody is shut in.
-- whatever a client makes of where its ray ended, a hit that has to go into one of them to get there isn't one
local Util = {}

-- from here on the part is in the way of what's meant for anybody behind it. whoever adds it removes it
function Util.add(part: BasePart, owner: Model)
	Owners[part] = owner
end

function Util.remove(part: BasePart)
	Owners[part] = nil
end

-- if a cover is between where a hit left from + the body it's meant for. what the attacker carries themselves is
-- never in their own way
function Util.getIfBetween(origin: Vector3, target: Model, attacker: Model?): boolean
	if next(Owners) == nil then
		return false
	end
	local goal = BodyUtil.getAimPosition(target, origin)
	for part, owner in Owners do
		if owner ~= attacker and getIfCrossed(part, origin, goal) then
			return true
		end
	end
	return false
end

return Util
