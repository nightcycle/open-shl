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
	Reach = 8.5,
	DrawDelay = 0.3,
	SheatheDelay = 0.25,
	Props = {
		{
			Limb = "RightHand",
			-- a cylinder lies along its x axis, the staff runs past the hand from back to front
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(4.5, 0.2, 0.2),
			Offset = CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(0, 0, 0.9),
			Color = BrickColor.new("Smoky grey").Color,
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			Size = Vector3.new(1.5, 1.5, 5.5),
			Offset = CFrame.new(0, 0, -0.9),
		},
	},
	SwingSound = "Slash",
}
-- how far off its middle the staff of shl1 is held
local SHL1_GRIP = 0.5
-- the staff of shl3 is a block along the way the hand points, it's its own hit box
local SHL3_SIZE = Vector3.new(0.5, 0.5, 7)
-- what it's drawn in unless the character has a color for the ability
local SHL3_COLOR = Color3.fromRGB(161, 161, 161)
-- how the hand holds it
local SHL3_OFFSET = CFrame.new(0.1, 0, -1.6) * CFrame.Angles(0, math.rad(180), math.rad(90))
-- Variables
-- References
-- Private Functions
-- Class
-- the staff is swung the same way in every game, how long it is + what a swing comes to isn't
return MeleeFactory.new(
	"basic-melee_bo-staff",
	GameDefinition.tune(CONFIG, {
		shl1 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 1.1
			config.Reach = 9
			-- it's in the hand the moment its tool is + heard as it comes out
			config.DrawDelay = nil
			config.SheatheDelay = nil
			config.DrawSound = "Unsheath"
			-- a longer staff, held nearer its middle
			local prop = config.Props[1]
			prop.Size = Vector3.new(5.8, 0.2, 0.2)
			prop.Offset = CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(0, 0, SHL1_GRIP)
			prop.Color = Color3.fromRGB(163, 162, 165)
			local hitbox = config.Hitboxes[1]
			hitbox.Size = Vector3.new(1.5, 1.5, 6.8)
			hitbox.Offset = CFrame.new(0, 0, -SHL1_GRIP)
			return config
		end),
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.Duration = 1.2
			-- a fifth of a second into the swing it starts to count, the first one it runs into is all it hits
			config.SwingDelay = 0.2
			config.MaxTargets = 1
			config.DrawDelay = 0.3
			config.SheatheDelay = 0.3
			-- nobody measured how far it got: the far end is 5.1 studs past the hand
			config.Reach = 10
			-- a list of its own: a block with a mesh mustn't carry the shape of the cylinder
			config.Props = {
				{
					Limb = "RightHand",
					Size = SHL3_SIZE,
					Offset = SHL3_OFFSET,
					Color = SHL3_COLOR,
					Material = Enum.Material.SmoothPlastic,
					Mesh = "BoStaff",
					MeshScale = Vector3.one * 1.5,
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
			-- the whole staff, from end to end
			config.Streaks = {
				{
					Limb = "RightHand",
					From = Vector3.new(0, 0, 3.5),
					To = Vector3.new(0, 0, -3.5),
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
