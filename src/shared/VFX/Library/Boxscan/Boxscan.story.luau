--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Boxscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Boxscan")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a slab sets out ahead of the user towards the target, the ghost of it stands where it got to: green where the
-- sweep ran into something, red where nothing was in its way. passing characters it goes through the target to
-- whatever is behind them. it's asked again with every frame, so the dummies can be moved about by hand
return VFXStory.newStateStory({
	Distance = UILabs.Slider(20, 4, 60, 1),
	Start = UILabs.Slider(4, 0, 20, 0.5),
	Range = UILabs.Slider(100, 0, 500, 1),
	Width = UILabs.Slider(7, 0.2, 30, 0.2),
	Height = UILabs.Slider(7, 0.2, 30, 0.2),
	Depth = UILabs.Slider(0.2, 0.2, 5, 0.2),
	IsPassingCharacters = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	local ghost = Instance.new("Part")
	ghost.Name = "BoxscanGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.Material = Enum.Material.ForceField
	ghost.Size = Vector3.new(controls.Width, controls.Height, controls.Depth)
	ghost.Parent = Workspace
	local function check()
		local origin = stage.User:GetPivot().Position
		local offset = stage.Target:GetPivot().Position - origin
		if offset.Magnitude <= 0 then
			return
		end
		local direction = offset.Unit
		local start = CFrame.lookAt(origin + direction * controls.Start, origin + direction * (controls.Start + 1))
		local hit = stage.ClientScope.fire(Boxscan, {
			CFrame = start,
			Size = ghost.Size,
			Direction = direction,
			Range = controls.Range,
			IsPassingCharacters = controls.IsPassingCharacters,
		})
		ghost.CFrame = start + direction * hit.Distance
		ghost.Color = if hit.Instance then Color3.new(0, 1, 0) else Color3.new(1, 0, 0)
	end
	check()
	local connection = RunService.Heartbeat:Connect(check)
	return function()
		connection:Disconnect()
		ghost:Destroy()
	end
end)
