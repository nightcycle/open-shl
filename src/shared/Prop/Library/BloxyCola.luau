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
-- a can of cola: it's opened as it's got out + a sip takes three seconds. the health the old one gave was switched
-- off, a sip is for show
return ConsumableFactory.new("bloxy-cola", {
	Size = Vector3.new(1, 1.2, 1),
	Mesh = "BloxyCola",
	MeshScale = Vector3.one * 1.2,
	-- of the hand from the can, the way the old tool gripped it: out in front
	RestOffset = CFrame.new(0.192, -0.015, 0.047, 0.217, 0.976, 0, 0, 0, -1, -0.976, 0.217, 0),
	-- tipped up at the mouth for as long as a sip takes
	UseOffset = CFrame.new(1.489, -0.382, 0.422, 1, 0, 0, 0, 0.759, -0.651, 0, 0.651, 0.759),
	DrawSound = "CanOpen",
	UseSound = "Drink",
})
