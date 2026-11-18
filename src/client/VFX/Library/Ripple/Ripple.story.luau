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
local DECALS = { "Shockwave", "PsychicWave" }
-- Variables
-- References
-- Private Functions
-- Class
-- it starts out as a shockwave around the user. with a speed it leaves from their right hand the way they face
-- instead
return VFXStory.newEventStory({
	Decal = UILabs.Choose(DECALS),
	Width = UILabs.Slider(4, 0.5, 16, 0.5),
	Depth = UILabs.Slider(4, 0.5, 16, 0.5),
	EndWidth = UILabs.Slider(34, 0.5, 60, 0.5),
	EndDepth = UILabs.Slider(34, 0.5, 60, 0.5),
	Lifetime = UILabs.Slider(1, 0.1, 5, 0.1),
	Speed = UILabs.Slider(0, 0, 60, 1),
}, function(stage: VFXStory.Stage, controls)
	local pivot = stage.User:GetPivot()
	local hand = stage.User:FindFirstChild("RightHand")
	local isTravelling = controls.Speed > 0 and hand ~= nil and hand:IsA("BasePart")
	stage.ClientScope.fire(ClientVFXDefinition.Ripple, {
		Decal = controls.Decal,
		CFrame = if isTravelling then pivot.Rotation + (hand :: BasePart).Position else pivot,
		Size = Vector3.new(controls.Width, 0.2, controls.Depth),
		EndSize = Vector3.new(controls.EndWidth, 0.2, controls.EndDepth),
		Lifetime = controls.Lifetime,
		Velocity = if isTravelling then pivot.LookVector * controls.Speed else nil,
	})
end)
