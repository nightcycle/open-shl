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
type Properties = ClientVFXType.Frost
-- Constants
local FROST_NAME = "Frost"
local TRANSPARENCY = 0.5
-- what's left of a block that hasn't grown yet or has shrunk away: a part is never no size at all
local MIN_SCALE = 0.01
-- Variables
-- References
-- Private Functions
-- Class
-- it's only seen: whoever is caught in it is held by the server's word, not by the ice
return ClientVFX.event(ClientVFXDefinition.Frost, function(props: Properties)
	local parts: { Part } = {}
	for index, block in props.Blocks do
		local part = Instance.new("Part")
		part.Name = FROST_NAME
		part.Material = Enum.Material.Ice
		part.Transparency = TRANSPARENCY
		part.Color = block.Color
		part.Size = block.Size * MIN_SCALE
		part.CFrame = props.CFrame * block.Offset
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = Workspace
		parts[index] = part
	end
	local shrinkDuration = math.min(props.ShrinkDuration or 0, props.Lifetime)
	local age = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		age += deltaTime
		if age >= props.Lifetime then
			connection:Disconnect()
			for _, part in parts do
				part:Destroy()
			end
			return
		end
		local left = if shrinkDuration > 0 then math.min((props.Lifetime - age) / shrinkDuration, 1) else 1
		for index, block in props.Blocks do
			local grown = if block.GrowDuration > 0 then math.min(age / block.GrowDuration, 1) else 1
			parts[index].Size = block.Size * math.max(grown * left, MIN_SCALE)
		end
	end)
end)
