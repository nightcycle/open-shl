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
local Util = {}

function Util.between(part0: BasePart, part1: BasePart)
	local weld = Instance.new("Weld")
	weld.Name = "Weld"
	weld.Part0 = part0
	weld.Part1 = part1
	-- the offset is kept local to part0, world positions far from the origin would cost it precision
	weld.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	weld.Parent = part1
	return weld
end

return Util
