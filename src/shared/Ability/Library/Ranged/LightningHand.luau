--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
-- Constants
local PARTICLES: { VFXAssetDefinition.ParticleKey } = { "LightningLeft", "LightningRight" }
table.freeze(PARTICLES)
local CONFIG: ShotFactory.Config = {
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
}
-- Variables
-- References
-- Private Functions
-- Class
-- the sparks are thrown the same way in every game, how soon + how often isn't
return ShotFactory.new(
	"ranged_lightning-hand",
	GameDefinition.tune(CONFIG, {
		shl1 = FreezeUtil.delta(CONFIG, function(config: ShotFactory.Config): ShotFactory.Config
			-- it's gone with the click + five of them leave in a second: nothing in the game takes off more
			config.ReleaseDelay = 0.05
			config.Duration = 0.2
			config.Speed = 60
			config.Lifetime = 5
			-- a ball of sparks has no end to stand on
			config.Size = Vector3.one
			config.Turn = nil
			return config
		end),
	})
)
