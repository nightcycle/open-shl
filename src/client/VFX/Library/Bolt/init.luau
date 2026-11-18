--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Projectile = require("@game/ReplicatedStorage/Shared/VFX/Library/Projectile")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Handle = VFXType.Handle
type Properties = ClientVFXType.Bolt
type ParticleKey = VFXAssetDefinition.ParticleKey
-- Constants
local BOLT_NAME = "Bolt"
-- how long what's left of a shot that landed takes to burn out
local FADE_DURATION = 3
-- a flame burns up the part it's on, turned like this it trails behind the shot instead
local FLAME_TURN = CFrame.Angles(math.pi / 2, 0, 0)
-- studs a shot has to have come since it was last moved for that to tell where it's headed
local MIN_STEP = 0.01
-- Variables
-- References
-- Private Functions
local function newEmitter(key: ParticleKey): ParticleEmitter
	local definition = VFXAssetDefinition.getParticle(key)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = key
	emitter.Texture = definition.TextureUrl
	emitter.Rate = definition.Rate
	emitter.Lifetime = definition.Lifetime
	emitter.Size = NumberSequence.new(definition.Size)
	emitter.Rotation = definition.Rotation
	emitter.Speed = NumberRange.new(definition.Speed)
	emitter.LightEmission = definition.LightEmission
	emitter.LockedToPart = definition.IsLockedToPart
	return emitter
end
-- Class
return ClientVFX.event(ClientVFXDefinition.Bolt, function(props: Properties, scope: ClientScope)
	local direction = props.Direction.Unit
	local turn = props.Turn or if props.FireSize then FLAME_TURN else CFrame.identity
	local part = Instance.new("Part")
	part.Name = BOLT_NAME
	part.Material = props.Material or Enum.Material.Neon
	part.Size = props.Size
	part.Color = props.Color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.lookAt(props.Origin, props.Origin + direction) * turn
	if props.Mesh then
		local definition = VFXAssetDefinition.getMesh(props.Mesh)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = definition.MeshUrl
		mesh.TextureId = definition.TextureUrl
		mesh.Scale = props.MeshScale or Vector3.one
		mesh.Parent = part
	end
	-- whatever it gives off on its way, all of it goes out as it lands
	local trails: { Instance } = {}
	if props.FireSize then
		local fire = Instance.new("Fire")
		fire.Heat = props.FireHeat or 14
		fire.Size = props.FireSize
		fire.Color = props.Color
		fire.SecondaryColor = props.SecondaryColor or props.Color
		table.insert(trails, fire)
	end
	if props.HasSparkles then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = props.Color
		table.insert(trails, sparkles)
	end
	local particles: { ParticleKey } = props.Particles or {}
	for _, key in particles do
		-- a loop makes a plain string of a key
		table.insert(trails, newEmitter(key :: ParticleKey))
	end
	for _, trail in trails do
		trail.Parent = part
	end
	if #trails > 0 then
		-- what it gives off flies on its own, the part that carries it stays out of sight
		part.Transparency = 1
	end
	part.Parent = Workspace

	local launchTime = os.clock()
	local heading = direction
	local lastPosition = props.Origin
	local handle: Handle
	local function land()
		handle.Stop()
		for _, trail in trails do
			-- a flame, sparkles + an emitter all go out the same way, which no class they share says
			(trail :: any).Enabled = false
		end
		local duration = FADE_DURATION
		if props.IsSticking then
			duration = math.max(props.Lifetime - (os.clock() - launchTime), 0)
		elseif #trails == 0 then
			part.Transparency = 1
		end
		task.delay(duration, function()
			part:Destroy()
		end)
	end
	handle = scope.start(Projectile, {
		Origin = props.Origin,
		Direction = direction,
		Speed = props.Speed,
		Lifetime = props.Lifetime,
		Gravity = props.Gravity,
		OnStep = function(position: Vector3)
			-- one that's pulled down points along its arc
			local step = position - lastPosition
			if props.Gravity and step.Magnitude > MIN_STEP then
				heading = step.Unit
			end
			lastPosition = position
			part.CFrame = CFrame.lookAt(position, position + heading) * turn
		end,
		OnHit = function(result: RaycastResult)
			land()
			if props.OnHit then
				props.OnHit(result)
			end
		end,
		OnExpired = land,
	})
end)
