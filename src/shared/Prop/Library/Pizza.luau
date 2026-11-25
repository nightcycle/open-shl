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
-- a slice of pizza: the burger with another mesh, a bite that's finished is a little health
return ConsumableFactory.new("pizza", {
	Size = Vector3.new(1, 0.8, 1),
	Mesh = "Pizza",
	-- of the hand from the slice, the way the old tool gripped it: out in front
	RestOffset = CFrame.new(0.718, -0.115, -0.114, -0.149, 0.989, 0, 0, 0, -1, -0.989, -0.149, 0),
	-- up at the mouth for as long as a bite takes
	UseOffset = CFrame.new(0.131, -0.799, 1.539, 0, -0.995, -0.1, 0, 0.1, -0.995, 1, 0, 0),
	DrawSound = "PizzaOpen",
	UseSound = "PizzaBite",
	Health = 1.6,
})
