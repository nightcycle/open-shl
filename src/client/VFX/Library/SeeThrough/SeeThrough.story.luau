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
-- it's the place itself that's looked through, from the camera of the story: what's around it goes see-through a
-- layer at a time + is put back as the effect stops. with a start of 80 + a range of 1 it's the shell the legacy
-- power caught by accident
return VFXStory.newStateStory({
	Range = UILabs.Slider(80, 1, 500, 1),
	Start = UILabs.Slider(0, 0, 500, 1),
	Transparency = UILabs.Slider(0.7, 0, 1, 0.05),
	RayCount = UILabs.Slider(400, 1, 2500, 1),
	PassCount = UILabs.Slider(3, 1, 10, 1),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.SeeThrough, {
		Range = controls.Range,
		Start = controls.Start,
		Transparency = controls.Transparency,
		RayCount = controls.RayCount,
		PassCount = controls.PassCount,
	}).Stop
end)
