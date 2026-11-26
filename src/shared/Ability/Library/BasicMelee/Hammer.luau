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
	Reach = 8,
	DrawDelay = 0.3,
	SheatheDelay = 0.25,
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.2, 4.5, 0.2),
			Offset = CFrame.new(0.15, 0, -1) * CFrame.Angles(0, math.pi, math.pi / 2),
			Color = BrickColor.new("Smoky grey").Color,
			Mesh = "Hammer",
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			-- taller than it's wide: the head sticks out above + below the hand
			Size = Vector3.new(1.5, 2.5, 4),
			Offset = CFrame.new(0, 0, -1.5),
		},
	},
	SwingSound = "Slash",
}
-- the hammer of shl3 is a block as big as its mesh, it's its own hit box
local SHL3_SIZE = Vector3.new(1.1, 4, 1.9)
-- what it's drawn in unless the character has a color for the ability
local SHL3_COLOR = Color3.fromRGB(161, 161, 161)
-- how the hand holds it: by the end of its shaft, the head out in front
local SHL3_OFFSET = CFrame.new(0, -1.3, 0.1) * CFrame.Angles(math.rad(-90), math.rad(180), 0)
-- Variables
-- References
-- Private Functions
-- Class
-- the hammer is swung the same way in every game, what it looks like + what a swing comes to isn't
return MeleeFactory.new(
	"basic-melee_hammer",
	GameDefinition.tune(CONFIG, {
		shl1 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 1
			-- it's in the hand the moment its tool is, heard as it comes out + as it's swung
			config.DrawDelay = nil
			config.SheatheDelay = nil
			config.DrawSound = "HammerDraw"
			config.SwingSound = "HammerSwing"
			-- the same hammer, a quarter bigger
			config.Props[1].MeshScale = Vector3.one * 1.25
			return config
		end),
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 0.8
			-- a fifth of a second into the swing it starts to count, the first one it runs into is all it hits
			config.SwingDelay = 0.2
			config.MaxTargets = 1
			config.DrawDelay = 0.3
			config.SheatheDelay = 0.3
			-- nobody measured how far it got: the head is 3.3 studs past the hand
			config.Reach = 8
			-- a mesh of its own
			config.Props = {
				{
					Limb = "RightHand",
					Size = SHL3_SIZE,
					Offset = SHL3_OFFSET,
					Color = SHL3_COLOR,
					Material = Enum.Material.SmoothPlastic,
					Mesh = "Hammer",
					MeshScale = Vector3.one * 1.05,
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
			-- a stud of the far face of the head
			config.Streaks = {
				{
					Limb = "RightHand",
					From = Vector3.new(0, 1, -0.95),
					To = Vector3.new(0, 2, -0.95),
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
