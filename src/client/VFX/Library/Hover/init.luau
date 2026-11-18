--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local Aim = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Aim")
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Hover
-- Constants
-- what pulls on the avatar is found under these names by whatever steers it
local POSITION_NAME = "HoverPosition"
local GYRO_NAME = "HoverGyro"
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Hover, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = character and character.PrimaryPart
	if not character or not humanoid or not rootPart then
		return function() end
	end
	if not RunService:IsRunning() then
		-- nothing is simulated in a place that isn't running, a story lifts the avatar by hand
		local ground = character:GetPivot()
		character:PivotTo(ground + Vector3.new(0, props.Height, 0))
		return function()
			character:PivotTo(ground)
		end
	end
	-- the movers are old, they're what gives flying the pull + the drift it has always had
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.Name = POSITION_NAME
	bodyPosition.MaxForce = Vector3.one * math.huge
	bodyPosition.Position = rootPart.Position + Vector3.new(0, props.Height, 0)
	bodyPosition.Parent = rootPart
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = GYRO_NAME
	bodyGyro.MaxTorque = Vector3.one * math.huge
	bodyGyro.CFrame = rootPart.CFrame
	bodyGyro.Parent = rootPart
	humanoid.PlatformStand = true
	local connection = RunService.RenderStepped:Connect(function()
		local position = Aim.get(character).Position
		if (position - rootPart.Position).Magnitude > 0.1 then
			bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, position)
		end
	end)
	return function()
		connection:Disconnect()
		bodyPosition:Destroy()
		bodyGyro:Destroy()
		humanoid.PlatformStand = false
	end
end)
