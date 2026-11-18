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
-- it's the view of the place itself that widens + comes back as the effect is stopped. a dummy never walks, so the
-- one that only counts on the move isn't shown
return VFXStory.newStateStory({
	FieldOfView = UILabs.Slider(100, 1, 120, 1),
	Duration = UILabs.Slider(0.5, 0, 5, 0.05),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.FieldOfView, {
		FieldOfView = controls.FieldOfView,
		Duration = controls.Duration,
	}).Stop
end)
