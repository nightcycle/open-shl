--!strict
-- Services
-- Packages
-- Modules
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
-- Constants
local PARTICLES: { VFXAssetDefinition.ParticleKey } = { "LightningLeft", "LightningRight" }
table.freeze(PARTICLES)
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new("ranged_lightning-hand", {
	ReleaseDelay = 0.6,
	Duration = 2,
	Limb = "RightHand",
	Speed = 80,
	Lifetime = 10,
	Size = Vector3.new(0.4, 0.4, 4),
	Color = BrickColor.new("Cyan").Color,
	Particles = PARTICLES,
	-- stood on its end the sparks make up a bolt as tall as the shot is long
	Turn = CFrame.Angles(math.pi / 2, 0, 0),
	LaunchSound = "Shock",
})
