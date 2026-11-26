--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
-- Types
-- Constants
local CONFIG: RayFactory.Config = {
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
}
-- Variables
-- References
-- Private Functions
-- Class
-- a ray out of the bare hand: nothing is held + nothing winds up. how far it gets + what's seen of it isn't the same
-- in every game
return RayFactory.new(
	"ranged_laser-ray",
	GameDefinition.tune(CONFIG, {
		shl1 = FreezeUtil.delta(CONFIG, function(config: RayFactory.Config): RayFactory.Config
			config.Duration = 1.5
			config.Range = 200
			-- a thin one that's there a while: held a quarter of a second, then half a second of going. the grey of
			-- a part nobody colored for a hero whose chest has no color to give it
			config.Beams = {
				{
					Thickness = 0.2,
					Transparency = 0.3,
					Lifetime = 0.75,
					IsFading = true,
					Color = Color3.fromRGB(163, 162, 165),
					IsSecondary = true,
				},
			}
			return config
		end),
	})
)
