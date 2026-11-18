--!strict
-- Services
local RunService = game:GetService("RunService")
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
-- moves what a weld holds from where it is to an offset, a step a frame. what it hands back stops it short
local function slide(weld: Weld, offset: CFrame, duration: number, onDone: (() -> ())?): () -> ()
	local origin = weld.C0
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local alpha = math.min(elapsed / duration, 1)
		weld.C0 = origin:Lerp(offset, alpha)
		if alpha >= 1 then
			connection:Disconnect()
			if onDone then
				onDone()
			end
		end
	end)
	return function()
		connection:Disconnect()
	end
end
-- Class
return ClientVFX.state(ClientVFXDefinition.Prop, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not character or not limb or not limb:IsA("BasePart") then
		return function() end
	end
	local part = Instance.new("Part")
	part.Name = PROP_NAME
	part.Shape = props.Shape or Enum.PartType.Block
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
		mesh.Scale = props.MeshScale or Vector3.one
		mesh.Offset = props.MeshOffset or Vector3.zero
		mesh.Parent = part
	end
	-- one that slides starts out where it comes out from
	local slideDuration = props.SlideDuration or 0
	local slideOffset = if slideDuration > 0 then props.SlideOffset else nil
	local offset = slideOffset or props.Offset
	part.CFrame = limb.CFrame * offset:Inverse()
	local weld = Instance.new("Weld")
	weld.Part0 = part
	weld.Part1 = limb
	weld.C0 = offset
	weld.Parent = part
	part.Parent = character
	if not slideOffset then
		return function()
			part:Destroy()
		end
	end
	local stop = slide(weld, props.Offset, slideDuration)
	return function()
		stop()
		-- it goes back the way it came before it's gone
		slide(weld, slideOffset, slideDuration, function()
			part:Destroy()
		end)
	end
end)
