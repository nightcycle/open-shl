--!strict
-- Services
-- Packages
-- Modules
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- the hand gives off snow for as long as the tool is out
local PLUME: ClientVFXType.Plume = { Limb = "RightHand", Particle = "Snow" }
table.freeze(PLUME)
-- the ray + the ice are this whatever the suit
local ICE = Color3.fromRGB(152, 194, 219)
-- Variables
-- References
-- Private Functions
-- Class
-- a ray out of the bare hand that shuts whoever it hurts in ice
return RayFactory.new("ranged_freeze-ray", {
	-- a fifth of a second, then the second it's listed with
	Duration = 1.2,
	-- whoever froze somebody waits out the five seconds they're held as well
	Stall = 5,
	Limb = "RightHand",
	Range = 500,
	Beams = {
		-- a thin one of ice inside a wide one that glows
		{
			Thickness = 0.4,
			Lifetime = 0.35,
			IsFading = true,
			Material = Enum.Material.Ice,
			Color = ICE,
			IsPlain = true,
		},
		{
			Thickness = 0.9,
			Transparency = 0.65,
			Lifetime = 0.35,
			IsFading = true,
			Color = ICE,
			IsPlain = true,
		},
	},
	Props = {},
	Plumes = { PLUME },
	FireSound = "PewPew",
})
