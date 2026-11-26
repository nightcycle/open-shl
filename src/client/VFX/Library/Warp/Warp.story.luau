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
-- every press sends the user a step on, past the target + away from it
return VFXStory.newEventStory({
	Distance = UILabs.Slider(12, 2, 60, 1),
	Step = UILabs.Slider(4, 1, 30, 1),
	IsHeadingKept = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	local pivot = stage.User:GetPivot()
	local offset = stage.Target:GetPivot().Position - pivot.Position
	local direction = if offset.Magnitude > 0.1 then offset.Unit else pivot.LookVector
	stage.ClientScope.fire(ClientVFXDefinition.Warp, {
		Position = pivot.Position + direction * controls.Step,
		IsHeadingKept = controls.IsHeadingKept,
	})
end)
