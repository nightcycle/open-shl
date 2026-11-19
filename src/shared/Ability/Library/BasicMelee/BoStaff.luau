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
	})
)
