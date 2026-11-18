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
type Properties = ClientVFXType.Plume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Plume, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return function() end
	end
	local definition = VFXAssetDefinition.getParticle(props.Particle)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = props.Particle
	emitter.Texture = definition.TextureUrl
	emitter.Rate = definition.Rate
	emitter.Lifetime = definition.Lifetime
	emitter.Size = NumberSequence.new(definition.Size, definition.EndSize or definition.Size)
	emitter.Rotation = definition.Rotation
	emitter.RotSpeed = NumberRange.new(definition.RotationSpeed or 0)
	emitter.Speed = NumberRange.new(definition.Speed)
	emitter.SpreadAngle = Vector2.one * (definition.SpreadAngle or 0)
	emitter.LightEmission = definition.LightEmission
	emitter.LockedToPart = definition.IsLockedToPart
	emitter.VelocityInheritance = definition.VelocityInheritance or 0
	if definition.Color then
		emitter.Color = definition.Color
	end
	if definition.Transparency then
		emitter.Transparency = definition.Transparency
	end
	emitter.Parent = limb
	return function()
		-- what's in the air by now gets to live out its life
		emitter.Enabled = false
		task.delay(definition.Lifetime.Max, function()
			emitter:Destroy()
		end)
	end
end)
