--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Prop
-- Constants
local PROP_NAME = "Prop"
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Prop, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not character or not limb or not limb:IsA("BasePart") then
		return function() end
	end
	local part = Instance.new("Part")
	part.Name = PROP_NAME
	part.Size = props.Size
	part.Color = props.Color
	part.Material = props.Material or Enum.Material.Plastic
	-- it's only there to be looked at: it can't push, be stood on or get in the way of a ray
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	if props.Mesh then
		local definition = VFXAssetDefinition.getMesh(props.Mesh)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = definition.MeshUrl
		mesh.TextureId = definition.TextureUrl
		mesh.Parent = part
	end
	part.CFrame = limb.CFrame * props.Offset:Inverse()
	local weld = Instance.new("Weld")
	weld.Part0 = part
	weld.Part1 = limb
	weld.C0 = props.Offset
	weld.Parent = part
	part.Parent = character
	return function()
		part:Destroy()
	end
end)
