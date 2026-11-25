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
-- a cup of coffee: a sip takes three seconds + keeps the next one off for a minute more. the rush it was made to
-- give was switched off in the old game, so the minute is all that's left of it: a click inside it is nothing
return ConsumableFactory.new("latte", {
	Size = Vector3.new(1, 1.2, 1),
	Mesh = "Latte",
	MeshScale = Vector3.one * 1.5,
	-- of the hand from the cup, the way the old tool gripped it: out in front
	RestOffset = CFrame.new(0.362, -0.115, 0.047, 0.217, 0.976, 0, 0, 0, -1, -0.976, 0.217, 0),
	-- tipped up at the mouth for as long as a sip takes
	UseOffset = CFrame.new(1.489, -0.382, 0.422, 1, 0, 0, 0, 0.759, -0.651, 0, 0.651, 0.759),
	UseSound = "Drink",
})
