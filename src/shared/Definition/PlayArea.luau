--!strict
-- Services
-- Packages
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
-- Types
type Box = {
	Min: Vector3,
	Max: Vector3,
}
-- Constants
-- a map marks the boxes an avatar may be sent into. the city this was written for marks none, its box is spelt out:
-- from its streets up to above its roofs. the sea around it + whatever is under the ground are left out
local BOX: Box? = GameDefinition.tune(nil :: Box?, {
	shl2 = table.freeze({
		Min = Vector3.new(-622.3, 40.24, -585),
		Max = Vector3.new(447.5, 433.84, 115.2),
	}),
})
-- Variables
-- References
-- Private Functions
local function getIfInsideBox(position: Vector3, box: Box): boolean
	local min, max = box.Min, box.Max
	return position.X > min.X
		and position.X < max.X
		and position.Y > min.Y
		and position.Y < max.Y
		and position.Z > min.Z
		and position.Z < max.Z
end

-- a marked box can sit at any angle, so the position is looked at from where the box stands
local function getIfInsidePart(position: Vector3, part: BasePart): boolean
	local offset = part.CFrame:PointToObjectSpace(position)
	local reach = part.Size / 2
	return math.abs(offset.X) < reach.X and math.abs(offset.Y) < reach.Y and math.abs(offset.Z) < reach.Z
end
-- Class
local Module = {}

-- the boxes are asked for with every call: under streaming a client holds them once its map came in, not before
Module.getIfInside = function(position: Vector3): boolean
	if BOX then
		return getIfInsideBox(position, BOX)
	end
	for _, part in MapDefinition.list(MapDefinition.PlayArea) do
		if getIfInsidePart(position, part) then
			return true
		end
	end
	return false
end

return Module
