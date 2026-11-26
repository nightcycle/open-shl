--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
-- Constants
local CONFIG: MeleeFactory.Config = {
	Duration = 0.8,
	Reach = 9,
	DrawDelay = 0.3,
	SheatheDelay = 0.25,
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.2, 4.5, 0.2),
			Offset = CFrame.new(0.15, 0, -1.5) * CFrame.Angles(0, math.pi, math.pi / 2),
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Sword",
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = Vector3.new(1.5, 1.5, 5),
			Offset = CFrame.new(0, 0, -2),
		},
	},
	SwingSound = "Slash",
}
-- the blade of shl3 is a block along the way the hand points, it's its own hit box
local SHL3_SIZE = Vector3.new(0.5, 0.5, 4.5)
-- what it's drawn in unless the character has a color for the ability
local SHL3_COLOR = Color3.fromRGB(161, 161, 161)
-- how the hand holds it
local SHL3_OFFSET = CFrame.new(0.1, 0, -1.6) * CFrame.Angles(0, math.rad(180), math.rad(90))
-- Variables
-- References
-- Private Functions
-- Class
-- the sword is swung the same way in every game, what it looks like + what a swing comes to isn't
return MeleeFactory.new(
	"basic-melee_sword",
	GameDefinition.tune(CONFIG, {
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 0.8
			-- a fifth of a second into the swing it starts to count, the first one it runs into is all it hits
			config.SwingDelay = 0.2
			config.MaxTargets = 1
			config.DrawDelay = 0.3
			config.SheatheDelay = 0.3
			-- nobody measured how far it got: the tip is 3.85 studs past the hand
			config.Reach = 9
			config.Props = {
				{
					Limb = "RightHand",
					Size = SHL3_SIZE,
					Offset = SHL3_OFFSET,
					Color = SHL3_COLOR,
					Material = Enum.Material.SmoothPlastic,
					Mesh = "Sword",
					MeshOffset = Vector3.new(0, 0, -0.2),
				},
			}
			-- a box is placed by where it is off the limb, a prop by where the limb is off it
			config.Hitboxes = {
				{
					Limb = "RightHand",
					Size = SHL3_SIZE,
					Offset = SHL3_OFFSET:Inverse(),
				},
			}
			-- along the blade, from tip to guard
			config.Streaks = {
				{
					Limb = "RightHand",
					From = Vector3.new(0, 0, 2.1),
					To = Vector3.new(0, 0, -1.5),
					Offset = SHL3_OFFSET,
					Lifetime = 0.07,
					Transparency = 0.75,
					Color = SHL3_COLOR,
				},
			}
			return config
		end),
	})
)
