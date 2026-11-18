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
local MATERIALS: { string } = { "Grass", "Brick", "Concrete", "Wood", "Metal", "Neon", "Sand", "Slate", "Plastic" }
-- Variables
-- References
-- Private Functions
-- Class
return VFXStory.newStateStory({
	Material = UILabs.Choose(MATERIALS),
	Color = UILabs.Datatype.Color3(Color3.fromRGB(86, 140, 60)),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Coat, {
		Material = (Enum.Material :: any)[controls.Material],
		Color = controls.Color,
	}).Stop
end)
