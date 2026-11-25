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
-- the box by the picnic rug, the pizza still in it. the old one was made to be thrown + never was: the one line
-- that threw it was switched off, so it's a thing to carry
return HeldFactory.new("pizza-box", {
	Limb = "RightHand",
	Size = Vector3.new(2, 2.05, 1.35),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-1.069, -1.015, 0.489, 0, -1, 0, 0, 0, -1, 1, 0, 0),
	Color = Color3.fromRGB(215, 197, 154),
	Mesh = "PizzaBox",
})
