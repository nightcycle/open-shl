--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local LIMBS = {
	"RightHand",
	"LeftHand",
	"RightLowerArm",
	"LeftLowerArm",
	"RightFoot",
	"LeftFoot",
	"Head",
	"UpperTorso",
	"LowerTorso",
}
local NO_MESH = "None"
-- a mesh keeps its own shape, the size only shows on a prop without one
local MESHES = { "Sword", NO_MESH }
local MATERIAL_NAMES = { "Plastic", "SmoothPlastic", "Metal", "Neon", "Glass", "ForceField", "Wood" }
local MATERIALS: { [string]: Enum.Material } = {
	Plastic = Enum.Material.Plastic,
	SmoothPlastic = Enum.Material.SmoothPlastic,
	Metal = Enum.Material.Metal,
	Neon = Enum.Material.Neon,
	Glass = Enum.Material.Glass,
	ForceField = Enum.Material.ForceField,
	Wood = Enum.Material.Wood,
}
-- Variables
-- References
-- Private Functions
-- Class
-- it starts out as the sword. the rotation is in degrees, turned around x, then y, then z
return VFXStory.newStateStory({
	Limb = UILabs.Choose(LIMBS),
	Mesh = UILabs.Choose(MESHES),
	Color = UILabs.Datatype.Color3(BrickColor.new("Smoky grey").Color),
	Material = UILabs.Choose(MATERIAL_NAMES),
	SizeX = UILabs.Slider(0.2, 0.1, 16, 0.1),
	SizeY = UILabs.Slider(4.5, 0.1, 16, 0.1),
	SizeZ = UILabs.Slider(0.2, 0.1, 16, 0.1),
	OffsetX = UILabs.Slider(0.15, -5, 5, 0.05),
	OffsetY = UILabs.Slider(0, -5, 5, 0.05),
	OffsetZ = UILabs.Slider(-1.5, -5, 5, 0.05),
	RotationX = UILabs.Slider(0, -180, 180, 5),
	RotationY = UILabs.Slider(180, -180, 180, 5),
	RotationZ = UILabs.Slider(90, -180, 180, 5),
}, function(stage: VFXStory.Stage, controls)
	local rotation =
		CFrame.Angles(math.rad(controls.RotationX), math.rad(controls.RotationY), math.rad(controls.RotationZ))
	return stage.ClientScope.start(ClientVFXDefinition.Prop, {
		Limb = controls.Limb,
		Size = Vector3.new(controls.SizeX, controls.SizeY, controls.SizeZ),
		Offset = CFrame.new(controls.OffsetX, controls.OffsetY, controls.OffsetZ) * rotation,
		Color = controls.Color,
		Material = MATERIALS[controls.Material],
		Mesh = if controls.Mesh == NO_MESH then nil else controls.Mesh,
	}).Stop
end)
