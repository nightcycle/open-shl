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
-- there's nothing to see on a dummy that stands still anyway, its humanoid shows what's held back
return VFXStory.newStateStory({}, function(stage: VFXStory.Stage)
	return stage.ClientScope.start(ClientVFXDefinition.Root, {}).Stop
end)
