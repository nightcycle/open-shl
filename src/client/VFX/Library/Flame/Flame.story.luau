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
-- it starts out as a fist on fire. the sparks are in the color of the rest of it unless they're given their own
return VFXStory.newStateStory({
	Limb = UILabs.Choose(LIMBS),
	Size = UILabs.Slider(2, 2, 30, 0.5),
	Heat = UILabs.Slider(0, -25, 25, 0.5),
	Color = UILabs.Datatype.Color3(BrickColor.new("Bright orange").Color),
	HasSecondaryColor = UILabs.Boolean(false),
	SecondaryColor = UILabs.Datatype.Color3(BrickColor.new("Bright red").Color),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Flame, {
		Limb = controls.Limb,
		Size = controls.Size,
		Heat = controls.Heat,
		Color = controls.Color,
		SecondaryColor = if controls.HasSecondaryColor then controls.SecondaryColor else nil,
	}).Stop
end)
