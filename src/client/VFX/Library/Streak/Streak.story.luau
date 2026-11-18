--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local RunService = game:GetService("RunService")
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local LIMBS = {
	"RightHand",
	"LeftHand",
	"RightFoot",
	"LeftFoot",
	"Head",
	"UpperTorso",
}
-- studs the user swings from side to side + how many times a second, a ribbon only shows on a limb that moves
local SWAY_DISTANCE = 4
local SWAY_RATE = 1.5
-- Variables
-- References
-- Private Functions
-- Class
-- nothing animates a dummy, so the user is swung from side to side for the ribbon to be drawn out. it starts out as
-- the one across a fist
return VFXStory.newStateStory({
	Limb = UILabs.Choose(LIMBS),
	FromX = UILabs.Slider(0.5, -5, 5, 0.1),
	FromY = UILabs.Slider(0, -5, 5, 0.1),
	FromZ = UILabs.Slider(-0.1, -5, 5, 0.1),
	ToX = UILabs.Slider(-0.5, -5, 5, 0.1),
	ToY = UILabs.Slider(0, -5, 5, 0.1),
	ToZ = UILabs.Slider(0.1, -5, 5, 0.1),
	Lifetime = UILabs.Slider(0.1, 0.01, 2, 0.01),
	Transparency = UILabs.Slider(0.75, 0, 1, 0.05),
	Delay = UILabs.Slider(0, 0, 2, 0.05),
	Linger = UILabs.Slider(0, 0, 2, 0.05),
	Color = UILabs.Datatype.Color3(Color3.fromRGB(161, 161, 161)),
}, function(stage: VFXStory.Stage, controls)
	local handle = stage.ClientScope.start(ClientVFXDefinition.Streak, {
		Limb = controls.Limb,
		From = Vector3.new(controls.FromX, controls.FromY, controls.FromZ),
		To = Vector3.new(controls.ToX, controls.ToY, controls.ToZ),
		Lifetime = controls.Lifetime,
		Transparency = controls.Transparency,
		Color = controls.Color,
		Delay = controls.Delay,
		Linger = controls.Linger,
	})
	local origin = stage.User:GetPivot()
	local elapsed = 0
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local sway = math.sin(elapsed * SWAY_RATE * 2 * math.pi) * SWAY_DISTANCE / 2
		stage.User:PivotTo(origin * CFrame.new(sway, 0, 0))
	end)
	return function()
		connection:Disconnect()
		stage.User:PivotTo(origin)
		handle.Stop()
	end
end)
