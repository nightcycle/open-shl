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
-- a dummy doesn't jump, what its humanoid is left with is printed as the effect starts + as it stops
return VFXStory.newStateStory({
	JumpPower = UILabs.Slider(300, 0, 500, 1),
}, function(stage: VFXStory.Stage, controls)
	local humanoid = stage.User:FindFirstChildWhichIsA("Humanoid")
	local handle = stage.ClientScope.start(ClientVFXDefinition.JumpPower, { JumpPower = controls.JumpPower })
	print(`jump power while on: {humanoid and humanoid.JumpPower}, gone by: {humanoid and humanoid.UseJumpPower}`)
	return function()
		handle.Stop()
		print(`jump power once off: {humanoid and humanoid.JumpPower}, gone by: {humanoid and humanoid.UseJumpPower}`)
	end
end)
