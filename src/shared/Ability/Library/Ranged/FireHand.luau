--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
-- Types
-- Constants
local CONFIG: ShotFactory.Config = {
	ReleaseDelay = 0.6,
	Duration = 2,
	Limb = "RightHand",
	Speed = 80,
	Lifetime = 10,
	Size = Vector3.new(0.4, 0.4, 4),
	Color = BrickColor.new("Bright orange").Color,
	FireSize = 7,
}
-- Variables
-- References
-- Private Functions
-- Class
-- the fire is thrown the same way in every game, how soon + how big a flame isn't
return ShotFactory.new(
	"ranged_fire-hand",
	GameDefinition.tune(CONFIG, {
		shl1 = FreezeUtil.delta(CONFIG, function(config: ShotFactory.Config): ShotFactory.Config
			-- it's gone with the click + the next one is right behind it
			config.ReleaseDelay = 0.05
			config.Duration = 0.5
			config.Speed = 100
			config.Lifetime = 5
			-- a ball under a bigger flame, in the colors the engine starts a fire out in
			config.Size = Vector3.one
			config.Color = Color3.fromRGB(236, 139, 70)
			config.SecondaryColor = Color3.fromRGB(139, 80, 55)
			config.FireSize = 10
			config.FireHeat = 16
			return config
		end),
	})
)
