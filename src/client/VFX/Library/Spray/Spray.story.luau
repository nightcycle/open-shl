--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local LIMBS = table.freeze({ "LeftHand", "RightHand" })
-- Variables
-- References
-- Private Functions
-- Class
-- icicles out of both hands of the user for as long as it's on, what they run into is printed. the pitch is how far
-- the way they leave is turned off the way a hand faces: at -90 they go the way the arm points
return VFXStory.newStateStory({
	Interval = UILabs.Slider(0.08, 0.02, 1, 0.01),
	Pitch = UILabs.Slider(-90, -180, 180, 5),
	Speed = UILabs.Slider(100, 5, 300, 5),
	Lifetime = UILabs.Slider(2, 0.5, 10, 0.5),
	Gravity = UILabs.Slider(196, 0, 250, 1),
	HasMesh = UILabs.Boolean(true),
	Color = UILabs.Datatype.Color3(BrickColor.new("Medium stone grey").Color),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Spray, {
		Limbs = LIMBS,
		Interval = controls.Interval,
		Turn = CFrame.Angles(math.rad(controls.Pitch), 0, 0),
		Speed = controls.Speed,
		Lifetime = controls.Lifetime,
		Gravity = controls.Gravity,
		Size = Vector3.new(0.2, 1, 0.2),
		Color = controls.Color,
		Material = if controls.HasMesh then Enum.Material.Plastic else nil,
		Mesh = if controls.HasMesh then "Icicle" :: VFXAssetDefinition.MeshKey else nil,
		OnHit = function(result: RaycastResult)
			print(`hit: {result.Instance:GetFullName()}`)
		end,
	}).Stop
end)
