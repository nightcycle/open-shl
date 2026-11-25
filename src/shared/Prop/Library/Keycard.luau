--!strict
-- Services
-- Packages
-- Modules
local HeldFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Held")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local ID = "keycard"
-- a bare blue card stood up in the hand, the way the old tool gripped it
local CARD: ClientVFXType.Prop = {
	Limb = "RightHand",
	Size = Vector3.new(0.05, 0.8, 1),
	Offset = CFrame.new(-0.011, -0.015, 0.169) * CFrame.Angles(math.pi / 2, 0, 0),
	Color = Color3.fromRGB(13, 105, 172),
	Material = Enum.Material.SmoothPlastic,
}
-- Variables
-- References
-- Private Functions
-- Class
-- the card of the prison. there's nothing to it but being held: whoever runs the gates asks the server who holds one
return HeldFactory.new(ID, CARD)
