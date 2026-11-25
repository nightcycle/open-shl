--!strict
-- Services
-- Packages
-- Modules
local ConsumableFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Consumable")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a slice of melon: bitten into like the burger, it comes out without a sound. the old one came to rest turned
-- after its first bite, a slip of its script that isn't kept
return ConsumableFactory.new("watermelon", {
	Size = Vector3.new(1, 0.8, 1),
	Mesh = "Watermelon",
	-- of the hand from the slice, the way the old tool gripped it: out in front
	RestOffset = CFrame.new(0.269, -0.615, -0.089, 0, 1, 0, 0, 0, -1, -1, 0, 0),
	-- up at the mouth for as long as a bite takes
	UseOffset = CFrame.new(-0.197, -0.376, -1.609, 0, 0.858, 0.514, 0, 0.514, -0.858, -1, 0, 0),
	UseSound = "WatermelonBite",
	Health = 1.6,
})
