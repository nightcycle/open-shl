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
-- the effect only tells whoever listens: what the line looks like is the story of the notice component
return VFXStory.newEventStory({
	Duration = UILabs.Slider(2, 0.1, 10, 0.1),
}, function(stage: VFXStory.Stage, controls)
	stage.ClientScope.fire(ClientVFXDefinition.Notice, {
		Text = "BRAINFREEZE!",
		Color = Color3.new(1, 0, 0),
		Duration = controls.Duration,
	})
end)
