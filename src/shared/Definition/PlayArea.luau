--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- the box of the city an avatar may be sent to: from its streets up to above its roofs. the sea around it + whatever
-- is under the ground are left out
local MIN = Vector3.new(-622.3, 40.24, -585)
local MAX = Vector3.new(447.5, 433.84, 115.2)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.getIfInside = function(position: Vector3): boolean
	return position.X > MIN.X
		and position.X < MAX.X
		and position.Y > MIN.Y
		and position.Y < MAX.Y
		and position.Z > MIN.Z
		and position.Z < MAX.Z
end

return Module
