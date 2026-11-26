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
-- the tablet out of the tech room of the heroes. a click with it is nothing: for as long as it's in the hand its
-- holder has its screen up, which is the client's own business
return HeldFactory.new("tablet", {
	Limb = "RightHand",
	Size = Vector3.new(1.2, 1.4, 0.2),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-0.112, -1.028, -0.125, -0.705, -0.709, 0, 0.071, -0.07, -0.995, 0.705, -0.702, 0.1),
	-- the mesh is drawn by its texture, the part under it never shows
	Color = Color3.new(1, 1, 1),
	Mesh = "Tablet",
})
