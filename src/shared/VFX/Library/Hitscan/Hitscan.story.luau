--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the line out of the right hand of the user ends where what they let go at the target does. it's green where that's
-- a character, yellow where it's anything else + red where nothing was in the way. passing characters it goes through
-- the target to whatever is behind them. it's asked again with every frame, so the dummies can be moved about by hand
return VFXStory.newStateStory({
	Distance = UILabs.Slider(20, 4, 60, 1),
	Range = UILabs.Slider(100, 1, 500, 1),
	IsPassingCharacters = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand")
	if not hand or not hand:IsA("BasePart") then
		return function() end
	end
	local line = Instance.new("BoxHandleAdornment")
	line.Adornee = hand
	line.AlwaysOnTop = true
	line.Transparency = 0.5
	line.Parent = hand
	local function check()
		local origin = hand.Position
		local offset = stage.Target:GetPivot().Position - origin
		if offset.Magnitude <= 0 then
			return
		end
		local hit = stage.ClientScope.fire(Hitscan, {
			Origin = origin,
			Direction = offset,
			Range = controls.Range,
			IsPassingCharacters = controls.IsPassingCharacters,
		})
		line.Size = Vector3.new(0.2, 0.2, hit.Distance)
		line.CFrame = hand.CFrame:ToObjectSpace(CFrame.lookAt(origin, hit.Position))
			* CFrame.new(0, 0, -hit.Distance / 2)
		line.Color3 = if hit.Target
			then Color3.new(0, 1, 0)
			elseif hit.Instance then Color3.new(1, 1, 0)
			else Color3.new(1, 0, 0)
	end
	check()
	local connection = RunService.Heartbeat:Connect(check)
	return function()
		connection:Disconnect()
		line:Destroy()
	end
end)
