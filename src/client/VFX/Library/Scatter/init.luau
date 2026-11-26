--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Scatter
-- Constants
local SCATTER_NAME = "Scatter"
-- they come to lie where they land instead of bouncing about
local PHYSICAL_PROPERTIES = PhysicalProperties.new(0.7, 0.3, 0.01)
local FACES = table.freeze({ Enum.NormalId.Top, Enum.NormalId.Bottom })
-- loose parts this client keeps at most, whoever threw them: the oldest go as more come. the old place made them on
-- the server, where one player who never stopped clicking kept hundreds alive for everybody
local MAX_PARTS = 300
-- Variables
local Parts: { Part } = {}
local random = Random.new()
-- References
-- Private Functions
local function remove(part: Part)
	local index = table.find(Parts, part)
	if index then
		table.remove(Parts, index)
	end
	part:Destroy()
end
-- Class
-- they're only this client's: where each one lands is nobody else's to see the same, + nobody stands on one
return ClientVFX.event(ClientVFXDefinition.Scatter, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return
	end
	local textureUrl = if props.Decal then VFXAssetDefinition.getDecal(props.Decal).TextureUrl else nil
	local parts: { Part } = {}
	for _ = 1, props.Count do
		-- every one its own way out from the hand, a little above it + turned the way it went
		local direction = random:NextUnitVector()
		local position = limb.Position + direction * props.Reach + Vector3.yAxis * props.Rise
		local part = Instance.new("Part")
		part.Name = SCATTER_NAME
		part.Size = props.Size
		part.Color = props.Color
		part.CustomPhysicalProperties = PHYSICAL_PROPERTIES
		part.CFrame = CFrame.lookAt(position, position + direction)
		-- loose + solid, so it comes to lie on the ground. it's in the way of no ray + sets nothing off
		part.CanQuery = false
		part.CanTouch = false
		if textureUrl then
			for _, face in FACES do
				local decal = Instance.new("Decal")
				decal.Texture = textureUrl
				decal.Face = face
				decal.Parent = part
			end
		end
		part.Parent = Workspace
		table.insert(parts, part)
		table.insert(Parts, part)
	end
	while #Parts > MAX_PARTS do
		remove(Parts[1])
	end
	task.delay(props.Lifetime, function()
		for _, part in parts do
			remove(part)
		end
	end)
end)
