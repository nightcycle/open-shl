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
-- it's left in the chest of the target, pointing the way a shot of the user would have flown: the target takes it
-- along if it's pushed. past the target there's nothing to stick in, it hangs where it was left
return VFXStory.newEventStory({
	Length = UILabs.Slider(2, 0.2, 8, 0.1),
	Thickness = UILabs.Slider(0.2, 0.05, 2, 0.05),
	Lifetime = UILabs.Slider(8, 0.05, 30, 0.05),
	IsPastTarget = UILabs.Boolean(false),
	Color = UILabs.Datatype.Color3(Color3.fromRGB(140, 110, 70)),
}, function(stage: VFXStory.Stage, controls)
	local origin = stage.User:GetPivot().Position
	local position = stage.Target:GetPivot().Position
	local direction = (position - origin).Unit
	stage.ClientScope.fire(ClientVFXDefinition.Shaft, {
		Position = if controls.IsPastTarget then position + direction * 6 else position - direction * 0.5,
		Direction = direction,
		Size = Vector3.new(controls.Thickness, controls.Thickness, controls.Length),
		Color = controls.Color,
		Lifetime = controls.Lifetime,
	})
end)
