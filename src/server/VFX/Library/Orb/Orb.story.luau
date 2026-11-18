--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Orb = require("@game/ServerScriptService/Server/VFX/Library/Orb")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the orb hangs where the target stands, who gets into the heart of it is printed: the target right away, the user
-- once they're dragged in by hand
return VFXStory.newStateStory({
	Distance = UILabs.Slider(12, 2, 40, 1),
	Diameter = UILabs.Slider(6, 1, 30, 0.5),
	CoreSize = UILabs.Slider(2, 0.5, 30, 0.5),
	Color = UILabs.Datatype.Color3(BrickColor.new("Cyan").Color),
}, function(stage: VFXStory.Stage, controls)
	return stage.ServerScope.start(Orb, {
		Position = stage.Target:GetPivot().Position,
		Diameter = controls.Diameter,
		CoreSize = controls.CoreSize,
		Color = controls.Color,
		OnEntered = function(character: Model)
			print(`entered: {character.Name}`)
		end,
	}).Stop
end)
