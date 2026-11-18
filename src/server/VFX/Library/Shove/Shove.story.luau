--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Shove = require("@game/ServerScriptService/Server/VFX/Library/Shove")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the target is sent off the way the user faces. nothing slows it down in a place that isn't running: it slides for
-- a moment + is put back, so the next press starts from the same spot
return VFXStory.newEventStory({
	Speed = UILabs.Slider(20, 0, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	stage.ServerScope.fire(Shove, {
		Target = stage.Target,
		Velocity = stage.User:GetPivot().LookVector * controls.Speed,
	})
end)
