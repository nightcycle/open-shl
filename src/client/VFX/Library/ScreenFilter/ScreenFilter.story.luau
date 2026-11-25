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
-- it's the view of the place itself that changes. a white tint is no tint
return VFXStory.newStateStory({
	Brightness = UILabs.Slider(0.3, -1, 1, 0.05),
	Contrast = UILabs.Slider(0.1, -1, 2, 0.05),
	Saturation = UILabs.Slider(-1, -1, 1, 0.05),
	Blur = UILabs.Slider(7, 0, 56, 1),
	TintColor = UILabs.Datatype.Color3(Color3.new(1, 1, 1)),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.ScreenFilter, {
		Brightness = controls.Brightness,
		Contrast = controls.Contrast,
		Saturation = controls.Saturation,
		Blur = controls.Blur,
		TintColor = controls.TintColor,
	}).Stop
end)
