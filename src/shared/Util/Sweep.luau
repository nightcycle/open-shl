--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- where something is that goes from one end of a way to the other + back for good, as a function of a clock alone.
-- two machines that read the same clock have it in the same place without a word between them: the server knows
-- where a beam is that it never moves, a client draws one that it's never told of
local Util = {}

-- how far along its way it is: 0 at the one end, 1 at the other. duration is the seconds one way takes, it's back
-- in as long again
function Util.getAlpha(now: number, duration: number): number
	return 1 - math.abs((now / duration) % 2 - 1)
end

function Util.getCFrame(from: CFrame, to: CFrame, now: number, duration: number): CFrame
	return from:Lerp(to, Util.getAlpha(now, duration))
end

-- the stretch of its way it went over from one look to the next, as two shares of it. an end it turned at in
-- between is in it
function Util.getRange(before: number, now: number, duration: number): (number, number)
	local alpha, priorAlpha = Util.getAlpha(now, duration), Util.getAlpha(before, duration)
	local low, high = math.min(alpha, priorAlpha), math.max(alpha, priorAlpha)
	local priorLeg, leg = math.floor(before / duration), math.floor(now / duration)
	-- a leg ends at the far end if it's the first, the third.. of them. two turns take in the whole way
	for turn = priorLeg + 1, math.min(leg, priorLeg + 2) do
		if turn % 2 == 1 then
			high = 1
		else
			low = 0
		end
	end
	return low, high
end

-- the box it went through since it was last looked at, so that a fast one skips nobody: it holds all of it at
-- both looks + wherever it was in between. size is its own, both ends of its way are turned the same
function Util.getSwept(
	from: CFrame,
	to: CFrame,
	size: Vector3,
	before: number,
	now: number,
	duration: number
): (CFrame, Vector3)
	local low, high = Util.getRange(before, now, duration)
	-- the way as the thing itself has it, so the box grows along its own axes
	local way = from:PointToObjectSpace(to.Position)
	local grown = size + Vector3.new(math.abs(way.X), math.abs(way.Y), math.abs(way.Z)) * (high - low)
	return from:Lerp(to, (low + high) / 2), grown
end

return Util
