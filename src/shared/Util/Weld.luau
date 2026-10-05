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

function Util.weldTo(part0: BasePart, part1: BasePart)
	local weld = Instance.new("Weld")
	weld.Name = "Weld"
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:Inverse()
	weld.C1 = part1.CFrame:Inverse()
	weld.Parent = part1
	return weld
end

return Util
