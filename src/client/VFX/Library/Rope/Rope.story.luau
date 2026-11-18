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
-- the rope runs from the right hand of the user to the target. thrown, its far end sets out from the hand + flies
-- there, otherwise it's there from the start
return VFXStory.newStateStory({
	Distance = UILabs.Slider(30, 4, 60, 1),
	IsThrown = UILabs.Boolean(true),
	Speed = UILabs.Slider(250, 5, 500, 5),
	Thickness = UILabs.Slider(0.1, 0.05, 2, 0.05),
	Color = UILabs.Datatype.Color3(BrickColor.new("Medium stone grey").Color),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand")
	if not hand or not hand:IsA("BasePart") then
		return function() end
	end
	return stage.ClientScope.start(ClientVFXDefinition.Rope, {
		Limb = hand.Name,
		Position = stage.Target:GetPivot().Position,
		Origin = if controls.IsThrown then hand.Position else nil,
		Speed = if controls.IsThrown then controls.Speed else nil,
		Thickness = controls.Thickness,
		Color = controls.Color,
	}).Stop
end)
