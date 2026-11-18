--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Hoist = require("@game/ServerScriptService/Server/VFX/Library/Hoist")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the target is picked up + put back down once the time is up. a press of the button while it's still up there
-- takes it higher for good, the story only knows where it was as it was pressed
return VFXStory.newEventStory({
	Height = UILabs.Slider(5, 0, 30, 0.5),
	Duration = UILabs.Slider(3, 0.5, 10, 0.5),
}, function(stage: VFXStory.Stage, controls)
	stage.ServerScope.fire(Hoist, {
		Target = stage.Target,
		Height = controls.Height,
		Duration = controls.Duration,
	})
end)
