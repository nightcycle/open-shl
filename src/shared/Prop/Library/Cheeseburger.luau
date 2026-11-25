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
-- a burger off a picnic table: a click is a bite, a bite that's finished is a little health. the health everybody
-- gets by themselves is half as quick
return ConsumableFactory.new("cheeseburger", {
	Size = Vector3.new(1, 0.8, 1),
	Mesh = "Cheeseburger",
	-- of the hand from the burger, the way the old tool gripped it: out in front
	RestOffset = CFrame.new(0.669, -0.115, 0.011, 0, 1, 0, 0, 0, -1, -1, 0, 0),
	-- up at the mouth for as long as a bite takes
	UseOffset = CFrame.new(-0.338, -0.648, -1.489, 0, 0.981, -0.196, 0, -0.196, -0.981, -1, 0, 0),
	-- the wrapper coming off as it's got out, then every bite
	DrawSound = "CheeseburgerOpen",
	UseSound = "CheeseburgerBite",
	Health = 1.6,
})
