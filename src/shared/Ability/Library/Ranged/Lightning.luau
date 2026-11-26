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
-- a bolt out of the bare hand that's there at once: the fastest thing the game has to hit with
return RayFactory.new("ranged_lightning", {
	-- a fifth of a second, then the three tenths it's listed with
	Duration = 0.5,
	Limb = "RightHand",
	Range = 500,
	Beams = {
		{
			Thickness = 0.4,
			Lifetime = 0.22,
			IsFading = true,
			Color = Color3.new(1, 1, 0),
			IsSecondary = true,
			-- a turn every ten studs, each a stud or two off the line
			Jitter = { Step = 10, Spread = 2 },
		},
	},
	Props = {},
	FireSound = "PewPew",
})
