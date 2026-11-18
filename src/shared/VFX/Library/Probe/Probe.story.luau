--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Probe = require("@game/ReplicatedStorage/Shared/VFX/Library/Probe")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the beam out of the user is as long as what they feel out ahead of them, which is where the target stands. it's
-- green up to whatever is in the way + red with nothing in range. it's asked again with every frame, so the dummies
-- can be moved about by hand
return VFXStory.newStateStory({
	Distance = UILabs.Slider(6, 2, 40, 1),
	Range = UILabs.Slider(50, 1, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	local userRoot = stage.User.PrimaryPart
	if not userRoot then
		return function() end
	end
	local beam = Instance.new("BoxHandleAdornment")
	beam.Adornee = userRoot
	beam.AlwaysOnTop = true
	beam.Transparency = 0.5
	beam.Parent = userRoot
	local function check()
		local distance = stage.ClientScope.fire(Probe, { Range = controls.Range })
		local length = distance or controls.Range
		beam.Size = Vector3.new(0.2, 0.2, length)
		beam.CFrame = CFrame.new(0, 0, -length / 2)
		beam.Color3 = if distance then Color3.new(0, 1, 0) else Color3.new(1, 0, 0)
	end
	check()
	local connection = RunService.Heartbeat:Connect(check)
	return function()
		connection:Disconnect()
		beam:Destroy()
	end
end)
