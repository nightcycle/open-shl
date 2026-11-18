--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Projectile = require("@game/ReplicatedStorage/Shared/VFX/Library/Projectile")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the ball is where the projectile is on its way from the user to the target. it turns green where it ran into
-- something + red where its time was up
return VFXStory.newStateStory({
	Distance = UILabs.Slider(30, 4, 60, 1),
	Speed = UILabs.Slider(80, 5, 300, 5),
	Lifetime = UILabs.Slider(3, 0.1, 10, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local userRoot = stage.User.PrimaryPart
	local targetRoot = stage.Target.PrimaryPart
	if not userRoot or not targetRoot then
		return function() end
	end
	local origin = userRoot.Position
	local ball = Instance.new("Part")
	ball.Name = "Projectile"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one
	ball.Material = Enum.Material.Neon
	ball.Color = Color3.new(1, 1, 0)
	ball.Anchored = true
	-- it marks the spot, it must not be what the projectile runs into
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Position = origin
	ball.Parent = stage.User.Parent
	local handle = stage.ClientScope.start(Projectile, {
		Origin = origin,
		Direction = targetRoot.Position - origin,
		Speed = controls.Speed,
		Lifetime = controls.Lifetime,
		OnStep = function(position: Vector3)
			ball.Position = position
		end,
		OnHit = function(result: RaycastResult)
			ball.Color = Color3.new(0, 1, 0)
			print(`hit: {result.Instance:GetFullName()}`)
		end,
		OnExpired = function()
			ball.Color = Color3.new(1, 0, 0)
			print("expired")
		end,
	})
	return function()
		handle.Stop()
		ball:Destroy()
	end
end)
