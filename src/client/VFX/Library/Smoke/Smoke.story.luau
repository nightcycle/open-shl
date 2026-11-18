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
	"UpperTorso",
	"HumanoidRootPart",
}
-- Variables
-- References
-- Private Functions
-- Class
-- it starts out as the cold that sinks off a hand. once it's stopped what's left of it clears by itself
return VFXStory.newStateStory({
	Limb = UILabs.Choose(LIMBS),
	Size = UILabs.Slider(4, 0.1, 30, 0.1),
	RiseVelocity = UILabs.Slider(-10, -25, 25, 0.5),
	Opacity = UILabs.Slider(0.5, 0, 1, 0.05),
	Color = UILabs.Datatype.Color3(BrickColor.new("Baby blue").Color),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Smoke, {
		Limb = controls.Limb,
		Size = controls.Size,
		RiseVelocity = controls.RiseVelocity,
		Opacity = controls.Opacity,
		Color = controls.Color,
	}).Stop
end)
