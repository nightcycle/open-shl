--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Barrier = require("@game/ServerScriptService/Server/VFX/Library/Barrier")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the wall goes up halfway between the dummies, facing the user
return VFXStory.newEventStory({
	Distance = UILabs.Slider(12, 4, 40, 1),
	Width = UILabs.Slider(7, 1, 30, 0.5),
	Height = UILabs.Slider(7, 1, 30, 0.5),
	Depth = UILabs.Slider(0.6, 0.1, 5, 0.1),
	Color = UILabs.Datatype.Color3(BrickColor.new("Cyan").Color),
	Lifetime = UILabs.Slider(2, 0, 20, 0.5),
	FadeDuration = UILabs.Slider(3.2, 0, 10, 0.1),
	Transparency = UILabs.Slider(0.2, 0, 1, 0.05),
	EndTransparency = UILabs.Slider(1, 0, 1, 0.05),
}, function(stage: VFXStory.Stage, controls)
	local userRoot = stage.User.PrimaryPart
	local targetRoot = stage.Target.PrimaryPart
	if not userRoot or not targetRoot then
		return
	end
	stage.ServerScope.fire(Barrier, {
		CFrame = CFrame.lookAt(userRoot.Position:Lerp(targetRoot.Position, 0.5), userRoot.Position),
		Size = Vector3.new(controls.Width, controls.Height, controls.Depth),
		Color = controls.Color,
		Lifetime = controls.Lifetime,
		FadeDuration = controls.FadeDuration,
		Transparency = controls.Transparency,
		EndTransparency = controls.EndTransparency,
	})
end)
