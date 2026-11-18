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
type Properties = ClientVFXType.Lift
-- Constants
local VELOCITY_NAME = "LiftVelocity"
-- only upwards: the avatar is free to be walked into whatever it rises along
local MAX_FORCE = Vector3.new(0, 1_500_000_000, 0)
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
	return function()
		bodyVelocity:Destroy()
	end
end)
