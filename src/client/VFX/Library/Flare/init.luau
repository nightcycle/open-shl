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
type Properties = ClientVFXType.Flare
-- Constants
local FLARE_NAME = "Flare"
-- Variables
-- References
-- Private Functions
-- Class
-- it rides the limb: an avatar that's on the move takes the spot along for as long as it gives them off
return ClientVFX.event(ClientVFXDefinition.Flare, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return
	end
	local definition = VFXAssetDefinition.getParticle(props.Particle)
	local attachment = Instance.new("Attachment")
	attachment.Name = FLARE_NAME
	attachment.Position = props.Offset or Vector3.zero
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
	if definition.LightInfluence then
		emitter.LightInfluence = definition.LightInfluence
	end
	if definition.Color then
		emitter.Color = definition.Color
	end
	if definition.Transparency then
		emitter.Transparency = definition.Transparency
	end
	emitter.Parent = attachment
	attachment.Parent = limb
	task.delay(props.Duration, function()
		-- what's in the air by now gets to live out its life
		emitter.Enabled = false
		task.delay(definition.Lifetime.Max, function()
			attachment:Destroy()
		end)
	end)
end)
