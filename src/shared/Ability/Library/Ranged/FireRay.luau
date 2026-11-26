--!strict
-- Services
-- Packages
-- Modules
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- the hand gives off embers for as long as the tool is out
local PLUME: ClientVFXType.Plume = { Limb = "RightHand", Particle = "Ember" }
table.freeze(PLUME)
-- Variables
-- References
-- Private Functions
-- Class
-- a ray out of the bare hand that sets whoever it reaches alight
return RayFactory.new("ranged_fire-ray", {
	-- a fifth of a second, then the second it's listed with
	Duration = 1.2,
	-- whoever set somebody alight waits out the five seconds they burn as well
	Stall = 5,
	-- the ray itself takes nothing off, the burn it starts does
	IsHarmless = true,
	Limb = "RightHand",
	Range = 500,
	Beams = {
		-- orange whatever the suit
		{
			Thickness = 0.4,
			Lifetime = 0.35,
			IsFading = true,
			Color = Color3.fromRGB(255, 59, 0),
			IsPlain = true,
		},
	},
	Props = {},
	Plumes = { PLUME },
	FireSound = "PewPew",
})
