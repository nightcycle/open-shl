--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Front = require("@game/ReplicatedStorage/Shared/VFX/Library/Front")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the box sets out from the right hand of the user the way they face, a red one is drawn along with it. it turns
-- green once it ran into the target + is gone as its time is up. the button sends the next one
return VFXStory.newEventStory({
	Distance = UILabs.Slider(8, 2, 40, 1),
	Speed = UILabs.Slider(20, 1, 100, 1),
	Lifetime = UILabs.Slider(1, 0.1, 5, 0.1),
	Width = UILabs.Slider(3, 0.2, 16, 0.2),
	Height = UILabs.Slider(3, 0.2, 16, 0.2),
	Depth = UILabs.Slider(3, 0.2, 16, 0.2),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local look = stage.User:GetPivot().LookVector
	local origin = CFrame.lookAt(hand.Position, hand.Position + look)
	local velocity = look * controls.Speed
	local size = Vector3.new(controls.Width, controls.Height, controls.Depth)
	local box = Instance.new("BoxHandleAdornment")
	box.Adornee = Workspace.Terrain
	box.Size = size
	box.CFrame = origin
	box.Color3 = Color3.new(1, 0, 0)
	box.Transparency = 0.6
	box.AlwaysOnTop = true
	box.Parent = stage.User
	local age = 0
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		age += deltaTime
		box.CFrame = origin + velocity * age
	end)
	local handle: VFXType.Handle
	handle = stage.ClientScope.start(Front, {
		CFrame = origin,
		Velocity = velocity,
		Size = size,
		Lifetime = controls.Lifetime,
		OnHit = function(target: Model)
			print(`hit: {target.Name}`)
			box.Color3 = Color3.new(0, 1, 0)
		end,
		OnExpired = function()
			handle.Stop()
			connection:Disconnect()
			box:Destroy()
		end,
	})
end)
