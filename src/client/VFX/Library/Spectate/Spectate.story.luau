--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
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
-- a place that isn't running has no other players, the target stands in for them: the buttons at the bottom of the
-- view of the place put the camera behind it + give it back
return VFXStory.newStateStory({}, function(stage: VFXStory.Stage)
	return stage.ClientScope.start(ClientVFXDefinition.Spectate, { Targets = { stage.Target } }).Stop
end)
