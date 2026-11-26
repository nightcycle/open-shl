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
-- the laser blast of shl1 turned around: whoever its ray reaches gets health back. never the one who lets it go, +
-- nobody a hit of theirs wouldn't land on either
return RayFactory.new("special_healing-ray", {
	Duration = 1.5,
	Limb = "RightHand",
	Range = 200,
	-- what it lands on gets this back, it takes nothing off
	Heal = 20,
	Beams = {
		-- green whatever the suit
		{
			Thickness = 0.2,
			Transparency = 0.3,
			Lifetime = 0.75,
			IsFading = true,
			Color = Color3.fromRGB(91, 154, 76),
			IsPlain = true,
		},
	},
	Props = {},
	FireSound = "PewPew",
})
