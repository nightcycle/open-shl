--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local HITBOX_SIZE = Vector3.new(1.5, 1.5, 3)
local HITBOX_OFFSET = CFrame.new(0, 0, -1)
-- Variables
-- References
-- Private Functions
-- the two hands hold the same sai the same way
local function newSai(limb: string): ClientVFXType.Prop
	return {
		Limb = limb,
		Size = Vector3.new(0.6, 0.4, 1.98),
		Offset = CFrame.new(0, 0, -1) * CFrame.Angles(0, math.pi, math.pi / 2):Inverse(),
		Color = Color3.fromRGB(99, 95, 98),
		Mesh = "Sai",
	}
end
-- Class
-- a sai in each hand, out the moment their tool is. they only count while they're swung + a swing takes its time
return MeleeFactory.new("basic-melee_sai", {
	Duration = 2,
	-- nobody measured how far they got: as far as the claws of shl2, the shortest pair there is
	Reach = 7,
	Props = { newSai("RightHand"), newSai("LeftHand") },
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = HITBOX_SIZE,
			Offset = HITBOX_OFFSET,
		},
		{
			Limb = "LeftHand",
			Size = HITBOX_SIZE,
			Offset = HITBOX_OFFSET,
		},
	},
})
