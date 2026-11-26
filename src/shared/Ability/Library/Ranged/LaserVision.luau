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
-- a ray out of each eye, five times a second for as long as the button is down. nothing is held + nothing winds up
return RayFactory.new("ranged_laser-vision", {
	Duration = 0.2,
	-- it goes on for as long as the button is down
	IsHeld = true,
	-- one from each eye, at once
	Burst = { Count = 2, Interval = 0 },
	Limb = "Head",
	-- a third of a stud either side of the nose, as far above the middle of the head as the eyes of shl2 are
	Offsets = { Vector3.new(0.35, 0.2, -0.6), Vector3.new(-0.35, 0.2, -0.6) },
	Range = 200,
	Beams = {
		-- red whatever the suit, there for the blink of an eye
		{
			Thickness = 0.2,
			Transparency = 0.5,
			Lifetime = 0.1,
			Color = Color3.fromRGB(255, 0, 0),
			IsPlain = true,
		},
	},
	Props = {},
	HeldSound = "LaserHum",
})
