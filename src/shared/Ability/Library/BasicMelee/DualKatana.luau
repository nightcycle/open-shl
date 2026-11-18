--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local HITBOX_SIZE = Vector3.new(1.5, 1.5, 5)
local HITBOX_OFFSET = CFrame.new(0, 0, -2)
-- Variables
-- References
-- Private Functions
-- the two hands hold the same blade the same way
local function newKatana(limb: string): ClientVFXType.Prop
	return {
		Limb = limb,
		Size = Vector3.new(0.4, 0.2, 4),
		Offset = CFrame.new(0, 0, -1.5) * CFrame.Angles(0, math.pi, math.pi / 2):Inverse(),
		Color = BrickColor.new("Smoky grey").Color,
		Mesh = "Katana",
		MeshScale = Vector3.one * 1.3,
	}
end
-- Class
return MeleeFactory.new("basic-melee_dual-katana", {
	Duration = 0.8,
	Reach = 9,
	DrawDelay = 0.6,
	SheatheDelay = 0.6,
	Props = { newKatana("LeftHand"), newKatana("RightHand") },
	Hitboxes = {
		{
			Limb = "LeftHand",
			Size = HITBOX_SIZE,
			Offset = HITBOX_OFFSET,
		},
		{
			Limb = "RightHand",
			Size = HITBOX_SIZE,
			Offset = HITBOX_OFFSET,
		},
	},
	DrawSound = "Unsheath",
	SheatheSound = "Sheath",
	SwingSound = "Slash",
})
