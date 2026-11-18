--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the sphere around the user is how far they reach, it's green for as long as the target is within. it's asked again
-- with every frame, so the dummies can be moved about by hand
return VFXStory.newStateStory({
	Distance = UILabs.Slider(6, 2, 40, 1),
	Range = UILabs.Slider(9, 0, 40, 0.5),
}, function(stage: VFXStory.Stage, controls)
	local userRoot = stage.User.PrimaryPart
	if not userRoot then
		return function() end
	end
	local sphere = Instance.new("SphereHandleAdornment")
	sphere.Adornee = userRoot
	sphere.Radius = controls.Range
	sphere.Transparency = 0.7
	sphere.AlwaysOnTop = true
	sphere.Parent = userRoot
	local function check()
		local isInReach = stage.ClientScope.fire(Reach, {
			Position = stage.Target:GetPivot().Position,
			Range = controls.Range,
		})
		sphere.Color3 = if isInReach then Color3.new(0, 1, 0) else Color3.new(1, 0, 0)
	end
	check()
	local connection = RunService.Heartbeat:Connect(check)
	return function()
		connection:Disconnect()
		sphere:Destroy()
	end
end)
