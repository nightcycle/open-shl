--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Reel
-- Constants
local VELOCITY_NAME = "ReelVelocity"
local GYRO_NAME = "ReelGyro"
local MAX_FORCE = Vector3.one * 10_000_000_000
-- studs off the spot the pull keeps the way it had from: there's no telling which way a spot is that the avatar is
-- right on top of
local MIN_DISTANCE = 1
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Reel, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local rootPart = character and character.PrimaryPart
	if not character or not rootPart then
		return function() end
	end
	if not RunService:IsRunning() then
		-- nothing is simulated in a place that isn't running, a story moves the avatar by hand
		local start = character:GetPivot()
		local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
			local offset = props.Position - character:GetPivot().Position
			if offset.Magnitude >= MIN_DISTANCE then
				local step = math.min(props.Speed * deltaTime, offset.Magnitude)
				character:PivotTo(character:GetPivot() + offset.Unit * step)
			end
		end)
		return function()
			connection:Disconnect()
			character:PivotTo(start)
		end
	end
	-- the movers are old, they're what gives the pull the feel it has always had
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = VELOCITY_NAME
	bodyVelocity.MaxForce = MAX_FORCE
	bodyVelocity.Velocity = Vector3.zero
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = GYRO_NAME
	bodyGyro.MaxTorque = Vector3.one * math.huge
	bodyGyro.CFrame = rootPart.CFrame
	local function update()
		local offset = props.Position - rootPart.Position
		if offset.Magnitude >= MIN_DISTANCE then
			bodyVelocity.Velocity = offset.Unit * props.Speed
		end
	end
	update()
	bodyVelocity.Parent = rootPart
	bodyGyro.Parent = rootPart
	local connection = RunService.Heartbeat:Connect(update)
	return function()
		connection:Disconnect()
		bodyVelocity:Destroy()
		bodyGyro:Destroy()
	end
end)
