--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Rope
-- Constants
local ROPE_NAME = "Rope"
-- studs ahead of the middle of the limb the rope is held at
local HOLD_OFFSET = 0.3
-- studs the rope has to be long to be shown at all, there's no pointing it at what's right where it's held
local MIN_LENGTH = 0.05
-- a cylinder lies along its side, the rope runs the way it looks
local TURN = CFrame.Angles(0, math.pi / 2, 0)
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Rope, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return function() end
	end
	local part = Instance.new("Part")
	part.Name = ROPE_NAME
	part.Shape = Enum.PartType.Cylinder
	part.Color = props.Color
	part.Anchored = true
	-- it's only there to be looked at: it can't push, be stood on or get in the way of a ray
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false

	local origin = props.Origin or props.Position
	local distance = (props.Position - origin).Magnitude
	local speed = props.Speed
	local startTime = os.clock()
	local function update()
		local alpha = if speed and distance > 0 then math.min(1, (os.clock() - startTime) * speed / distance) else 1
		local tip = origin:Lerp(props.Position, alpha)
		local hold = limb.Position + limb.CFrame.LookVector * HOLD_OFFSET
		local length = (tip - hold).Magnitude
		if length < MIN_LENGTH then
			part.Transparency = 1
			return
		end
		part.Transparency = 0
		part.Size = Vector3.new(length, props.Thickness, props.Thickness)
		part.CFrame = CFrame.lookAt(hold:Lerp(tip, 0.5), tip) * TURN
	end
	update()
	part.Parent = Workspace
	local connection = RunService.Heartbeat:Connect(update)
	return function()
		connection:Disconnect()
		part:Destroy()
	end
end)
