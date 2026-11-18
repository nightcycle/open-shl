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
-- a dummy doesn't walk, the pace its humanoid is left with is printed as the effect starts + as it stops
return VFXStory.newStateStory({
	WalkSpeed = UILabs.Slider(80, 0, 200, 1),
}, function(stage: VFXStory.Stage, controls)
	local humanoid = stage.User:FindFirstChildWhichIsA("Humanoid")
	local handle = stage.ClientScope.start(ClientVFXDefinition.WalkSpeed, { WalkSpeed = controls.WalkSpeed })
	print(`walk speed while on: {humanoid and humanoid.WalkSpeed}`)
	return function()
		handle.Stop()
		print(`walk speed once off: {humanoid and humanoid.WalkSpeed}`)
	end
end)
