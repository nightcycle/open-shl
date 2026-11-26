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
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Line
-- Constants
local LINE_NAME = "Line"
local END_NAME = "LineEnd"
-- studs the line has to be long to be shown at all, there's no pointing it at what's right where it's tied
local MIN_LENGTH = 0.05
-- a cylinder lies along its side, the line runs the way it looks
local TURN = CFrame.Angles(0, math.pi / 2, 0)
-- Variables
-- References
-- Private Functions
-- only there to be looked at: it can't push, be stood on or get in the way of a ray
local function newPart(name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end
-- Class
-- drawn by whoever sees it, nothing hangs on it: the old pole had a rope of the server with a loose part on its end
return ClientVFX.state(ClientVFXDefinition.Line, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return function() end
	end
	local line = newPart(LINE_NAME)
	line.Shape = Enum.PartType.Cylinder
	line.Color = props.Color
	local tip = newPart(END_NAME)
	tip.Size = props.EndSize
	tip.Color = props.EndColor
	tip.Material = props.EndMaterial or Enum.Material.Plastic
	if props.EndMesh then
		local definition = VFXAssetDefinition.getMesh(props.EndMesh)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = definition.MeshUrl
		mesh.TextureId = definition.TextureUrl
		mesh.Scale = props.EndMeshScale or Vector3.one
		mesh.Parent = tip
	end
	local turn = props.EndTurn or CFrame.identity
	local function update()
		local tie = limb.CFrame * props.Offset
		local far = tie - Vector3.yAxis * props.Length
		local position = props.Position
		if position then
			-- it lies where it was put for as long as the line reaches, + is dragged along behind once it doesn't
			local span = position - tie
			far = if span.Magnitude > props.Length then tie + span.Unit * props.Length else position
		end
		tip.CFrame = CFrame.new(far) * turn
		local length = (far - tie).Magnitude
		if length < MIN_LENGTH then
			line.Transparency = 1
			return
		end
		line.Transparency = 0
		line.Size = Vector3.new(length, props.Thickness, props.Thickness)
		line.CFrame = CFrame.lookAt(tie:Lerp(far, 0.5), far) * TURN
	end
	update()
	line.Parent = Workspace
	tip.Parent = Workspace
	local connection = RunService.Heartbeat:Connect(update)
	return function()
		connection:Disconnect()
		line:Destroy()
		tip:Destroy()
	end
end)
