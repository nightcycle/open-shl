--!strict
-- Services
-- Packages
-- Modules
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
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
table.freeze(CARD)
-- the arm out in front, what a hand that holds anything used to do by itself
local HOLD_ANIMATION: AnimationKey = "GunHolding"
-- Variables
-- References
-- Private Functions
-- Class
local definitionRes = PropDefinition.get(ID)
assert(definitionRes.IsOk, `no prop is registered as "{ID}"`)

-- the card of the prison. there's nothing to it but being held: whoever runs the gates asks the server who holds one
return table.freeze({
	Prop = definitionRes.Value,
	Card = CARD,
	HoldAnimation = HOLD_ANIMATION,
})
