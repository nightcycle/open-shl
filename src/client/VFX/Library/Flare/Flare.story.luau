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
local LIMBS = {
	"RightHand",
	"LeftHand",
	"Head",
	"HumanoidRootPart",
}
-- a game only has a row for some of them, one it has none for isn't its to give off
local PARTICLES = { "Flash", "Snow", "Ember", "Tornado", "LightningLeft", "LightningRight" }
-- Variables
-- References
-- Private Functions
-- Class
-- a spot ahead of the hand of the user gives them off for a moment + is gone once the last of them is
return VFXStory.newEventStory({
	Limb = UILabs.Choose(LIMBS),
	Particle = UILabs.Choose(PARTICLES),
	Duration = UILabs.Slider(0.2, 0.05, 2, 0.05),
	Ahead = UILabs.Slider(1, 0, 4, 0.1),
}, function(stage: VFXStory.Stage, controls)
	stage.ClientScope.fire(ClientVFXDefinition.Flare, {
		Limb = controls.Limb,
		Offset = Vector3.new(0, 0, -controls.Ahead),
		Particle = controls.Particle,
		Duration = controls.Duration,
	})
end)
