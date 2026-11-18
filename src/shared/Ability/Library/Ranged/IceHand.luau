--!strict
-- Services
-- Packages
-- Modules
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new("ranged_ice-hand", {
	ReleaseDelay = 0.6,
	Duration = 2,
	Limb = "RightHand",
	Speed = 80,
	Lifetime = 10,
	Size = Vector3.new(0.4, 0.4, 4),
	Color = Color3.fromRGB(124, 203, 255),
	FireSize = 7,
	SecondaryColor = Color3.new(1, 1, 1),
})
