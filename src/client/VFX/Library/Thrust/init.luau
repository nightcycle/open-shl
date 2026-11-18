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
type Properties = ClientVFXType.Thrust
-- Constants
local POSITION_NAME = "HoverPosition"
-- studs a second a story moves the avatar at, nothing pulls on it there
local STORY_SPEED = 30
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Thrust, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local rootPart = character and character.PrimaryPart
	if not character or not rootPart then
		return function() end
	end
	local isRunning = RunService:IsRunning()
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local offset = Aim.get(character).Position - rootPart.Position
		if offset.Magnitude < 0.1 then
			return
		end
		if not isRunning then
			local step = math.min(STORY_SPEED * deltaTime, offset.Magnitude)
			character:PivotTo(character:GetPivot() + offset.Unit * step)
			return
		end
		-- only an avatar that hovers has something to be pulled by
		local bodyPosition = rootPart:FindFirstChild(POSITION_NAME)
		if bodyPosition and bodyPosition:IsA("BodyPosition") then
			bodyPosition.Position = rootPart.Position + offset.Unit * props.Power
		end
	end)
	return function()
		connection:Disconnect()
	end
end)
