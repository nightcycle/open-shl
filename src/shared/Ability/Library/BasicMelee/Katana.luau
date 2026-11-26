--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- one blade in the right hand: it's out the moment its tool is + the first one a swing runs into is all it hits
return MeleeFactory.new("basic-melee_katana", {
	Duration = 1,
	-- nobody measured how far it got: as far as the sword + the two katanas of shl2
	Reach = 9,
	MaxTargets = 1,
	DrawSound = "Unsheath",
	SwingSound = "Slash",
	Props = {
		{
			Limb = "RightHand",
			Size = Vector3.new(0.4, 0.2, 3.2),
			Offset = CFrame.new(0, 0, -1.4) * CFrame.Angles(0, math.pi, math.pi / 2):Inverse(),
			Color = Color3.fromRGB(99, 95, 98),
			Mesh = "Katana",
			MeshScale = Vector3.one * 1.2,
		},
	},
	Hitboxes = {
		{
			Limb = "RightHand",
			-- the blade as its mesh draws it + a stud
			Size = Vector3.new(1.5, 1.5, 4.8),
			Offset = CFrame.new(0, 0, -1.9),
		},
	},
})
