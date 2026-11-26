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
-- Variables
-- References
-- Private Functions
-- Class
-- the line of the fishing pole off the hand of the user: hanging, or cast at the feet of the target. with less
-- line than it takes to get there its end is dragged along
return VFXStory.newStateStory({
	Distance = UILabs.Slider(12, 2, 60, 1),
	IsCast = UILabs.Boolean(false),
	Length = UILabs.Slider(3, 0.5, 80, 0.5),
	Thickness = UILabs.Slider(0.02, 0.01, 0.5, 0.01),
	HasFish = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Line, {
		Limb = "RightHand",
		Offset = Vector3.new(0, -1, -4),
		Position = if controls.IsCast then stage.Target:GetPivot().Position - Vector3.yAxis * 3 else nil,
		Length = controls.Length,
		Thickness = controls.Thickness,
		Color = Color3.fromRGB(248, 248, 248),
		EndSize = Vector3.one * 0.2,
		EndColor = Color3.fromRGB(159, 161, 172),
		EndMaterial = Enum.Material.Glass,
		EndMesh = if controls.HasFish then "FishSilver" :: "FishSilver" else "Sinker" :: "Sinker",
		EndMeshScale = Vector3.new(0.25, 0.3, 0.25),
		EndTurn = CFrame.Angles(-math.pi / 2, 0, 0),
	}).Stop
end)
