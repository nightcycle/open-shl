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
-- a bottle of bloxiade: the latte in another bottle, a sip + a minute before the next
return ConsumableFactory.new("bloxiade", {
	Size = Vector3.new(1, 1.6, 1),
	Mesh = "Bloxiade",
	-- of the hand from the bottle, the way the old tool gripped it: out in front
	RestOffset = CFrame.new(0.362, -0.115, 0.047, 0.217, 0.976, 0, 0, 0, -1, -0.976, 0.217, 0),
	-- tipped up at the mouth for as long as a sip takes
	UseOffset = CFrame.new(1.388, -0.267, 0.405, 0.996, 0, -0.093, -0.051, 0.836, -0.547, 0.078, 0.549, 0.832),
	UseSound = "Drink",
})
