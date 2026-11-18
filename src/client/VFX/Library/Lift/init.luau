--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Probe = require("@game/ReplicatedStorage/Shared/VFX/Library/Probe")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Lift
-- Constants
local VELOCITY_NAME = "LiftVelocity"
local HOLD_FORCE = 20_000
-- upwards nothing gets in its way. sideways it's held just hard enough that rubbing along what it rises on doesn't
-- shove the avatar about, whatever it runs into still stops it
local MAX_FORCE = Vector3.new(HOLD_FORCE, 1_500_000_000, HOLD_FORCE)
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Lift, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local rootPart = character and character.PrimaryPart
	if not character or not rootPart then
		return function() end
	end
	if not RunService:IsRunning() then
		-- nothing is simulated in a place that isn't running, a story raises the avatar by hand
		local ground = character:GetPivot()
		local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
			character:PivotTo(character:GetPivot() + Vector3.new(0, props.Speed * deltaTime, 0))
		end)
		return function()
			connection:Disconnect()
			character:PivotTo(ground)
		end
	end
	-- the mover is old, it's what gives the rise the feel it has always had
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = VELOCITY_NAME
	bodyVelocity.MaxForce = MAX_FORCE
	bodyVelocity.Velocity = Vector3.new(0, props.Speed, 0)
	bodyVelocity.Parent = rootPart
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	-- the avatar still goes where its player walks it, only never into what it's up against: pressed into a wall
	-- its body rubs along it + drifts off to the side
	local connection = RunService.Heartbeat:Connect(function()
		local walk = if humanoid then humanoid.MoveDirection * humanoid.WalkSpeed else Vector3.zero
		if scope.fire(Probe, { Range = props.Clearance }) then
			local look = rootPart.CFrame.LookVector
			walk -= look * math.max(0, walk:Dot(look))
		end
		bodyVelocity.Velocity = Vector3.new(walk.X, props.Speed, walk.Z)
	end)
	return function()
		connection:Disconnect()
		bodyVelocity:Destroy()
	end
end)
