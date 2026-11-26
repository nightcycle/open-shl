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
-- a place that isn't running has no other players, the target stands in for them: the buttons at the bottom of the
-- view of the place put the camera behind it + give it back. one that's bare + starts on the first is behind the
-- target right away
return VFXStory.newStateStory({
	IsStarted = UILabs.Boolean(false),
	IsBare = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Spectate, {
		Targets = { stage.Target },
		Index = if controls.IsStarted then 1 else nil,
		IsBare = controls.IsBare,
	}).Stop
end)
