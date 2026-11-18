--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Properties = ClientVFXType.Ripple
-- Constants
local RIPPLE_NAME = "Ripple"
-- it's seen from above + from below
local FACES = table.freeze({ Enum.NormalId.Top, Enum.NormalId.Bottom })
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.event(ClientVFXDefinition.Ripple, function(props: Properties)
	local part = Instance.new("Part")
	part.Name = RIPPLE_NAME
	-- only what's on its faces is seen
	part.Transparency = 1
	part.Size = props.Size
	part.CFrame = props.CFrame
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	local definition = VFXAssetDefinition.getDecal(props.Decal)
	local decals: { Decal } = {}
	for _, face in FACES do
		local decal = Instance.new("Decal")
		decal.Texture = definition.TextureUrl
		decal.Face = face
		decal.Parent = part
		table.insert(decals, decal)
	end
	part.Parent = Workspace

	local velocity = props.Velocity or Vector3.zero
	local age = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		age += deltaTime
		local alpha = age / props.Lifetime
		if alpha >= 1 then
			connection:Disconnect()
			part:Destroy()
			return
		end
		part.Size = props.Size:Lerp(props.EndSize, alpha)
		part.CFrame = props.CFrame + velocity * age
		for _, decal in decals do
			decal.Transparency = alpha
		end
	end)
end)
