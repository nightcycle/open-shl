--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- the spot of the box of a part that's closest to another one, which is that spot itself for one inside of it
local function getBoxPosition(part: BasePart, near: Vector3): Vector3
	local cframe = part.CFrame
	local halfSize = part.Size / 2
	local offset = cframe:PointToObjectSpace(near)
	return cframe:PointToWorldSpace(
		Vector3.new(
			math.clamp(offset.X, -halfSize.X, halfSize.X),
			math.clamp(offset.Y, -halfSize.Y, halfSize.Y),
			math.clamp(offset.Z, -halfSize.Z, halfSize.Z)
		)
	)
end
-- Class
-- where a body that can be hit is, whoever plays it + if nobody does
local Util = {}

-- the spot a body is held to when a hit on it is claimed from around `near`. an avatar is held to its middle, from
-- wherever. a body nobody plays may be as wide as a street, with its middle further off than anything reaches: it's
-- held to the spot of its own parts' boxes that's closest, + to its middle as well if it has no part of its own
function Util.getAimPosition(body: Model, near: Vector3): Vector3
	if not AttributeDefinition.get(body, AttributeDefinition.IsNonPlayer) then
		return body:GetPivot().Position
	end
	local aimPosition: Vector3? = nil
	local aimDistance = math.huge
	for _, part in body:GetChildren() do
		if part:IsA("BasePart") then
			local position = getBoxPosition(part, near)
			local distance = (position - near).Magnitude
			if distance < aimDistance then
				aimPosition = position
				aimDistance = distance
			end
		end
	end
	return aimPosition or body:GetPivot().Position
end

return Util
