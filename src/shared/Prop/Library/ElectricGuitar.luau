--!strict
-- Services
-- Packages
-- Modules
local HeldFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Held")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- one of the guitars in a row downstairs in the apartments. it's carried, nobody plays it
return HeldFactory.new("electric-guitar", {
	Limb = "RightHand",
	Size = Vector3.new(5, 1.2, 0.25),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-1.435, -0.087, -0.13, -0.858, 0.291, 0.424, -0.514, -0.485, -0.707, 0, -0.825, 0.565),
	-- the mesh is drawn by its texture, the part under it never shows
	Color = Color3.new(1, 1, 1),
	Mesh = "ElectricGuitar",
})
