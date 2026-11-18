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
-- the user takes off + is pulled to the target, which is where a story aims
return VFXStory.newStateStory({
	Distance = UILabs.Slider(30, 4, 60, 1),
	Height = UILabs.Slider(10, 0, 30, 0.5),
	Power = UILabs.Slider(35, 1, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	-- only an avatar that hovers has something to be pulled by
	local hover = stage.ClientScope.start(ClientVFXDefinition.Hover, { Height = controls.Height })
	local thrust = stage.ClientScope.start(ClientVFXDefinition.Thrust, { Power = controls.Power })
	return function()
		thrust.Stop()
		hover.Stop()
	end
end)
