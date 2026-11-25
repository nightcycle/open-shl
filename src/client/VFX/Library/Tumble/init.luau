--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AcrobaticsDefinition = require("@game/ReplicatedStorage/Shared/Definition/Acrobatics")
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Plan = require("@self/Plan")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Tumble
-- Constants
local STEP = AcrobaticsDefinition.STEP
local VELOCITY_NAME = "TumbleVelocity"
local GYRO_NAME = "TumbleGyro"
-- the movers are old + turned up the way the old place had them: what throws the body is twice as stiff as the engine
-- makes one, what turns it ten times. it's what gives a flip the snap it has always had
local VELOCITY_POWER = 2_500
local VELOCITY_MAX_FORCE = Vector3.one * 9_990_000
local GYRO_POWER = 30_000
local GYRO_MAX_TORQUE = Vector3.one * 99_900_000
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Tumble, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = character and character.PrimaryPart
	if not character or not humanoid or not rootPart then
		return function() end
	end
	local plan = Plan.get(props)
	local lift = plan.Lift
	local turn = plan.Turn
	-- the root of a body stands where the torso of the old ones did + carries the rest of it
	local origin = rootPart.CFrame
	local forward = origin.LookVector * props.Forward
	-- nothing is simulated in a place that isn't running, a story carries the avatar along the plan by hand
	local isSimulated = RunService:IsRunning()
	local position = origin.Position
	local rotation = origin.Rotation
	local velocity = Vector3.zero

	local bodyVelocity: BodyVelocity? = nil
	local bodyGyro: BodyGyro? = nil
	if isSimulated then
		humanoid.PlatformStand = true
		-- a move that's thrown nowhere has nothing carry it: the body turns over where it stands
		if #lift > 0 then
			local mover = Instance.new("BodyVelocity")
			mover.Name = VELOCITY_NAME
			mover.P = VELOCITY_POWER
			mover.MaxForce = VELOCITY_MAX_FORCE
			mover.Parent = rootPart
			bodyVelocity = mover
		end
		if props.IsTurned then
			local mover = Instance.new("BodyGyro")
			mover.Name = GYRO_NAME
			mover.P = GYRO_POWER
			mover.MaxTorque = GYRO_MAX_TORQUE
			mover.CFrame = origin
			mover.Parent = rootPart
			bodyGyro = mover
		end
	end

	local isHeld = true
	-- the body is its humanoid's again. what throws it may still be on: a throw that outlasts its turn carries the
	-- body on for the rest of it
	local function release()
		if not isHeld then
			return
		end
		isHeld = false
		if bodyGyro then
			bodyGyro:Destroy()
		end
		if isSimulated then
			humanoid.PlatformStand = false
		end
	end

	local connection: RBXScriptConnection? = nil
	local isOver = false
	local function stop()
		if isOver then
			return
		end
		isOver = true
		if connection then
			connection:Disconnect()
		end
		if bodyVelocity then
			bodyVelocity:Destroy()
		end
		release()
		if not isSimulated then
			character:PivotTo(origin)
		end
	end

	-- a step of the old scheduler: the throw goes on to its next speed, the turn to its next target. the step after
	-- the last of either is the one that ends it
	local function take(index: number)
		if index <= #lift then
			velocity = forward + Vector3.new(0, lift[index], 0)
			if bodyVelocity then
				bodyVelocity.Velocity = velocity
			end
		else
			if bodyVelocity then
				bodyVelocity:Destroy()
				bodyVelocity = nil
			end
			-- let go of, it falls
			velocity -= Vector3.new(0, Workspace.Gravity * STEP, 0)
		end
		if index <= #turn then
			local target = turn[index]
			if typeof(target) == "CFrame" then
				rotation = origin.Rotation * target
			end
		elseif index == #turn + 1 then
			-- back to how it stood before it's let go of
			rotation = origin.Rotation
		else
			release()
		end
		if bodyGyro and isHeld then
			bodyGyro.CFrame = rotation
		end
		if not isSimulated then
			position += velocity * STEP
			position = Vector3.new(position.X, math.max(position.Y, origin.Position.Y), position.Z)
			character:PivotTo(rotation + position)
		end
		if index > #lift and index > #turn + 1 then
			stop()
			if props.OnEnded then
				props.OnEnded()
			end
		end
	end

	-- time is summed + a step is taken for every thirtieth of a second of it, so a move lasts what it always did
	-- whatever the frames of this machine take
	local index = 1
	local elapsed = 0
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		while elapsed >= STEP and not isOver do
			elapsed -= STEP
			index += 1
			take(index)
		end
	end)
	take(index)

	return stop
end)
