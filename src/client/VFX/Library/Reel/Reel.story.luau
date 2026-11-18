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
-- the user is pulled to where the target stands + put back as the effect stops
return VFXStory.newStateStory({
	Distance = UILabs.Slider(40, 4, 60, 1),
	Speed = UILabs.Slider(75, 5, 200, 5),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Reel, {
		Position = stage.Target:GetPivot().Position,
		Speed = controls.Speed,
	}).Stop
end)
