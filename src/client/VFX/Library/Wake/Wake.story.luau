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
-- studs across the circle the user is carried around + how many times a second, a ribbon only shows behind what moves
local CIRCLE_DIAMETER = 12
local CIRCLE_RATE = 0.5
-- Variables
-- References
-- Private Functions
-- Class
-- nothing moves a dummy, so the user is carried around in a circle, facing the way it goes. without its own colors
-- every ribbon is the color of the part it's behind
return VFXStory.newStateStory({
	HasColors = UILabs.Boolean(true),
	Color = UILabs.Datatype.Color3(Color3.fromRGB(30, 90, 220)),
	SecondaryColor = UILabs.Datatype.Color3(Color3.fromRGB(240, 200, 40)),
	Lifetime = UILabs.Slider(0.2, 0.01, 2, 0.01),
	Depth = UILabs.Slider(0.5, 0, 4, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local handle = stage.ClientScope.start(ClientVFXDefinition.Wake, {
		Color = if controls.HasColors then controls.Color else nil,
		SecondaryColor = if controls.HasColors then controls.SecondaryColor else nil,
		Lifetime = controls.Lifetime,
		Depth = controls.Depth,
	})
	local origin = stage.User:GetPivot()
	local elapsed = 0
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local angle = elapsed * CIRCLE_RATE * 2 * math.pi
		stage.User:PivotTo(
			origin
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(0, 0, -CIRCLE_DIAMETER / 2)
				* CFrame.Angles(0, math.pi / 2, 0)
		)
	end)
	return function()
		connection:Disconnect()
		stage.User:PivotTo(origin)
		handle.Stop()
	end
end)
