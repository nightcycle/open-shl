--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Cover = require("@game/ServerScriptService/Server/VFX/Library/Cover")
local CoverUtil = require("@game/ServerScriptService/Server/Util/Cover")
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local MATERIALS: { [string]: Enum.Material } = {
	Neon = Enum.Material.Neon,
	Ice = Enum.Material.Ice,
	ForceField = Enum.Material.ForceField,
}
-- seconds after it's all there or all gone that the target lets a ray go at the user
local RAY_DELAY = 0.25
local RAY_RANGE = 500
-- Variables
-- References
-- Private Functions
-- Class
-- the user carries it, ahead of them is towards the target. the target lets a ray go at them once it's up + once
-- more when it's gone: what the ray ended at + whether the server would take a hit from there are printed
return VFXStory.newStateStory({
	Distance = UILabs.Slider(20, 4, 60, 1),
	Width = UILabs.Slider(12, 0.2, 30, 0.2),
	Height = UILabs.Slider(7, 0.2, 30, 0.2),
	Depth = UILabs.Slider(0.2, 0.2, 30, 0.2),
	Ahead = UILabs.Slider(5, -10, 20, 0.5),
	Up = UILabs.Slider(1, -10, 10, 0.5),
	Color = UILabs.Datatype.Color3(Color3.new(0, 1, 1)),
	Material = UILabs.Choose({ "Neon", "Ice", "ForceField" }),
	Transparency = UILabs.Slider(0.7, 0, 1, 0.05),
	FadeDuration = UILabs.Slider(0.5, 0, 5, 0.1),
	GrowDuration = UILabs.Slider(0, 0, 5, 0.1),
	Delay = UILabs.Slider(0.3, 0, 5, 0.1),
	Linger = UILabs.Slider(0.3, 0, 5, 0.1),
	GoneDuration = UILabs.Slider(0, 0, 5, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local user, target = stage.User, stage.Target
	local function check(label: string)
		if not user.Parent or not target.Parent then
			return
		end
		local origin = target:GetPivot().Position
		local hit = stage.newServerScope(target).fire(Hitscan, {
			Origin = origin,
			Direction = user:GetPivot().Position - origin,
			Range = RAY_RANGE,
		})
		local found = if hit.Target then hit.Target.Name elseif hit.Instance then hit.Instance.Name else "nothing"
		print(
			`{label}: the ray ended at {found}, a cover is in its way: {CoverUtil.getIfBetween(origin, user, target)}`
		)
	end
	local handle = stage.ServerScope.start(Cover, {
		Size = Vector3.new(controls.Width, controls.Height, controls.Depth),
		Offset = CFrame.new(0, controls.Up, -controls.Ahead),
		Color = controls.Color,
		Material = MATERIALS[controls.Material],
		Transparency = controls.Transparency,
		FadeDuration = controls.FadeDuration,
		GrowDuration = controls.GrowDuration,
		Delay = controls.Delay,
		Linger = controls.Linger,
		GoneDuration = controls.GoneDuration,
	})
	local showDuration = controls.Delay + math.max(controls.FadeDuration, controls.GrowDuration)
	local thread = task.delay(showDuration + RAY_DELAY, check, "up")
	return function()
		task.cancel(thread)
		handle.Stop()
		local goDuration = controls.Linger + math.max(controls.FadeDuration, controls.GrowDuration)
		task.delay(goDuration + controls.GoneDuration + RAY_DELAY, check, "gone")
	end
end)
