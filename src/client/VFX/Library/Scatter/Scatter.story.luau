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
-- the bills of the moneybag, thrown from the hand of the user. a place that isn't running drops nothing: they hang
-- where they started until their time is up
return VFXStory.newEventStory({
	Count = UILabs.Slider(5, 1, 15, 1),
	Reach = UILabs.Slider(2, 0, 8, 0.1),
	Rise = UILabs.Slider(4, 0, 8, 0.1),
	Lifetime = UILabs.Slider(5, 0.5, 60, 0.5),
	HasDecal = UILabs.Boolean(true),
}, function(stage: VFXStory.Stage, controls)
	stage.ClientScope.fire(ClientVFXDefinition.Scatter, {
		Limb = "RightHand",
		Count = controls.Count,
		Size = Vector3.new(2, 0.4, 1),
		Color = BrickColor.new("Dark green").Color,
		Decal = if controls.HasDecal then "Bill" :: "Bill" else nil,
		Reach = controls.Reach,
		Rise = controls.Rise,
		Lifetime = controls.Lifetime,
	})
end)
