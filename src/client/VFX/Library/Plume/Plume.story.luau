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
	"HumanoidRootPart",
	"RightHand",
	"LeftHand",
	"Head",
}
local PARTICLES = { "Tornado", "LightningLeft", "LightningRight" }
-- Variables
-- References
-- Private Functions
-- Class
-- it starts out as the funnel of wind around the user. once it's stopped what's in the air still lives out its life
return VFXStory.newStateStory({
	Limb = UILabs.Choose(LIMBS),
	Particle = UILabs.Choose(PARTICLES),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Plume, {
		Limb = controls.Limb,
		Particle = controls.Particle,
	}).Stop
end)
