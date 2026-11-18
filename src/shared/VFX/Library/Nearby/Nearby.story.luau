--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Nearby = require("@game/ReplicatedStorage/Shared/VFX/Library/Nearby")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the sphere around the user is how far it looks, it's green for as long as the target is found. it's asked again
-- with every frame, so the dummies can be moved about by hand
return VFXStory.newStateStory({
	Distance = UILabs.Slider(8, 2, 40, 1),
	Range = UILabs.Slider(12, 1, 40, 0.5),
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
		local targets = stage.ClientScope.fire(Nearby, { Range = controls.Range })
		sphere.Color3 = if table.find(targets, stage.Target) then Color3.new(0, 1, 0) else Color3.new(1, 0, 0)
	end
	check()
	local connection = RunService.Heartbeat:Connect(check)
	return function()
		connection:Disconnect()
		sphere:Destroy()
	end
end)
