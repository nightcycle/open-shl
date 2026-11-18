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
local LIGHT_NAME = "StoryLight"
-- Variables
-- References
-- Private Functions
-- Class
-- the user is the one that goes, the target stays to compare against. with a fade duration it eases out + back in
-- as the effect is stopped. the user carries a light in its chest for the unlit one to put out
return VFXStory.newStateStory({
	Transparency = UILabs.Slider(1, 0, 1, 0.05),
	FadeDuration = UILabs.Slider(0, 0, 5, 0.05),
	IsUnlit = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	local torso = stage.User:FindFirstChild("UpperTorso")
	local light = Instance.new("PointLight")
	light.Name = LIGHT_NAME
	light.Color = Color3.fromRGB(90, 160, 255)
	light.Range = 12
	light.Brightness = 2
	light.Parent = torso
	local handle = stage.ClientScope.start(ClientVFXDefinition.Cloak, {
		Transparency = controls.Transparency,
		FadeDuration = controls.FadeDuration,
		IsUnlit = controls.IsUnlit,
	})
	return function()
		handle.Stop()
		-- it's left for as long as the avatar takes to come back, so it's seen to go on again
		task.delay(controls.FadeDuration, function()
			light:Destroy()
		end)
	end
end)
