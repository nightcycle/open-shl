--!strict
-- Services
-- Packages
-- Modules
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
-- Constants
-- of the hand from the gun: where the old tool was gripped, behind + below its middle, tilted the way the guns of
-- the game are held so the barrel runs on along the arm
local GRIP = CFrame.new(0, -0.3, 0.86) * CFrame.Angles(math.pi / 2 - math.pi / 20, 0, 0)
-- Variables
-- References
-- Private Functions
-- Class
-- ten shots a second for as long as the button is down, until the clip is empty: then nothing for as long as filling
-- it takes. a shot is there at once + strays a little
return RayFactory.new("ranged_machine-gun", {
	Duration = 0.1,
	IsHeld = true,
	Limb = "RightHand",
	-- the far end of the barrel
	Offset = GRIP:Inverse() * Vector3.new(0, 0.5, -1.7),
	Range = 400,
	-- a fiftieth of how far off what's pointed at is, either way
	Spread = 0.02,
	Clip = { Size = 45, ReloadDuration = 5 },
	Beams = {
		-- a tracer that's all but not there: grey whatever the suit
		{
			Thickness = 0.2,
			Transparency = 0.9,
			Lifetime = 0.05,
			Material = Enum.Material.Plastic,
			Color = Color3.fromRGB(163, 162, 165),
			IsPlain = true,
		},
	},
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.5, 1.6, 3.2),
			Offset = GRIP,
			Color = Color3.fromRGB(17, 17, 17),
			Mesh = "MachineGun",
		},
	},
	FireSound = "GunShot",
})
