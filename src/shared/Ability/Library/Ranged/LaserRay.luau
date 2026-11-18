--!strict
-- Services
-- Packages
-- Modules
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a ray out of the bare hand: nothing is held + nothing winds up
return RayFactory.new("ranged_laser-ray", {
	-- a fifth of a second, then the second it's listed with
	Duration = 1.2,
	Limb = "RightHand",
	Range = 500,
	Beams = {
		{
			Thickness = 0.9,
			Transparency = 0.25,
			Lifetime = 0.35,
			IsFading = true,
			Color = Color3.new(0, 1, 1),
			IsSecondary = true,
		},
	},
	Props = {},
	FireSound = "PewPew",
})
