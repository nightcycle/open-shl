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
-- the guitar off the picnic table in the park. what it used to play left with the scripts of the old tool: it's
-- carried, nobody strums it
return HeldFactory.new("acoustic-guitar", {
	Limb = "RightHand",
	Size = Vector3.new(1.5, 0.5, 3.375),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-0.027, -0.155, 1.337, 0.228, -0.232, 0.946, -0.342, -0.928, -0.146, 0.912, -0.29, -0.291),
	-- the mesh is drawn by its texture, the part under it never shows
	Color = Color3.new(1, 1, 1),
	Mesh = "AcousticGuitar",
})
