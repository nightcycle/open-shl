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
return VFXStory.newStateStory({
	Height = UILabs.Slider(10, 0, 30, 0.5),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Hover, { Height = controls.Height }).Stop
end)
