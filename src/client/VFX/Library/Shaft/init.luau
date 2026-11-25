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
type Properties = ClientVFXType.Shaft
-- Constants
local SHAFT_NAME = "Shaft"
-- studs short of where it sticks the look for what it sticks in starts + how far that goes: what it ran into is
-- right there, each side only ever has that to a hair
local PROBE_BACK = 0.5
local PROBE_LENGTH = 1
-- Variables
-- References
-- Private Functions
-- Class
-- whatever it sticks in that can move takes it along: a limb of somebody, a door. in anything else, or in nothing a
-- viewer can find there, it stays where it is
return ClientVFX.event(ClientVFXDefinition.Shaft, function(props: Properties, _scope: ClientScope)
	local direction = props.Direction.Unit
	local part = Instance.new("Part")
	part.Name = SHAFT_NAME
	part.Size = props.Size
	part.Color = props.Color
	part.CFrame = CFrame.lookAt(props.Position, props.Position + direction)
	part.CastShadow = false
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
	local result = Workspace:Raycast(props.Position - direction * PROBE_BACK, direction * PROBE_LENGTH)
	local carrier = result and result.Instance
	if carrier and not carrier.Anchored then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part
		weld.Part1 = carrier
		weld.Parent = part
		-- under what carries it, so it's gone with that as well
		part.Parent = carrier
	else
		part.Anchored = true
		part.Parent = Workspace
	end
	task.delay(props.Lifetime, function()
		part:Destroy()
	end)
end)
