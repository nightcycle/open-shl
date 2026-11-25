--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Aim = AbilityType.Aim
type Memory = AbilityType.Memory
type ClientContext = AbilityType.ClientContext
type AnimationKey = VFXAssetDefinition.AnimationKey
-- what only the player who shoots needs to know
export type Config = {
	HoldAnimation: AnimationKey?, -- for as long as the tool is out, the avatar holds it its own way without
	CastAnimation: AnimationKey?, -- from the click on
	FireAnimation: AnimationKey?, -- with every ray that leaves
}
-- Constants
-- how many rays the character let go so far, the next one goes by it
local COUNT_KEY = "RayCount"
-- how many it had let go as the cast began that's letting its rays go
local CAST_COUNT_KEY = "CastRayCount"
-- casts left in the clip as the player's own machine has it, full without
local ROUNDS_KEY = "Rounds"
-- when the clip began to be filled, nil unless it is
local RELOAD_TIME_KEY = "ReloadTime"
-- studs the spot pointed at has to be off the limb for the ray to be headed there
local MIN_AIM_DISTANCE = 0.01
-- Variables
-- every ray that strays rolls how far for itself
local Rng = Random.new()
-- References
-- Private Functions
-- Class
local Module = {}

-- what the clip of an ability is at as the player's own machine has it, for whoever shows it: the casts left in it +
-- whether it's being filled. while it is the count goes up with the time that takes. a clip that never runs dry
-- has none left to count
Module.getRounds = function(ability: RayFactory.Ability, record: Memory): (number, boolean)
	local clip = ability.Config.Clip
	if not clip then
		return 0, false
	end
	local reloadTime = record[RELOAD_TIME_KEY] :: number?
	if reloadTime then
		return clip.Size * math.clamp((os.clock() - reloadTime) / clip.ReloadDuration, 0, 1), true
	end
	return (record[ROUNDS_KEY] or clip.Size) :: number, false
end

-- the client half of a ray ability: the player sees their own cast + their own beam the moment it happens, their
-- machine is the one to say where a ray leaves from + what's in its way. the server may find it ended sooner, the beam
-- is put right once its word is back
Module.new = function(ability: RayFactory.Ability, config: Config): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	local clip = shared.Clip
	local reload = bindings.Reload

	-- lets one ray of a cast go at what the player pointed at, from wherever the limb is by now
	local function release(context: ClientContext, aim: Aim, index: number)
		local limb = context.Character:FindFirstChild(shared.Limb)
		if not limb or not limb:IsA("BasePart") then
			return
		end
		local spot = RayFactory.getOffset(shared, index)
		local from = if spot then limb.CFrame:PointToWorldSpace(spot) else limb.Position
		local offset = aim.Position - from
		if shared.Spread then
			local stray = Vector3.new(Rng:NextNumber(-1, 1), Rng:NextNumber(-1, 1), Rng:NextNumber(-1, 1))
			offset += stray * (offset.Magnitude * shared.Spread)
		end
		-- pointed right at the limb there's no telling where to, the ray goes where the avatar looks
		local direction = if offset.Magnitude > MIN_AIM_DISTANCE
			then offset.Unit
			else context.Character:GetPivot().LookVector
		local hit = context.VFX.fire(Hitscan, { Origin = from, Direction = direction, Range = shared.Range })
		if not hit then
			return
		end
		local id = ((context.Record[COUNT_KEY] or 0) :: number) + 1
		context.Record[COUNT_KEY] = id
		context.raise(bindings.Fire, {
			Id = id,
			Origin = from,
			Direction = direction,
			-- a vector is only so exact: what's right at the end of the range can come back a hair past it
			Distance = math.min(hit.Distance, shared.Range),
			Target = hit.Target,
		})
	end

	local builder = AbilityBuilder.newClient(layout)
	for _, cast in RayFactory.getCasts(ability) do
		if clip and reload then
			-- a cast with nothing left in the clip has it filled instead
			builder = builder:Guard(cast, function(context: ClientContext): boolean
				if Module.getRounds(ability, context.Record) >= 1 then
					return true
				end
				context.raise(reload, nil)
				return false
			end)
		end
		builder = builder
			-- the server has the last word on the energy, a cast it's sure to turn down isn't started on
			:Guard(
				cast,
				function(context: ClientContext): boolean
					local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
					if ModeDefinition.getIfEnergyEnabled() and energy < energyCost then
						context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
						return false
					end
					return true
				end
			)
		local castAnimation = config.CastAnimation
		if castAnimation then
			builder = builder:Fire(cast, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
				return { Animation = castAnimation :: AnimationKey }
			end)
		end
		builder = builder:On(cast, function(context: ClientContext)
			if clip then
				-- a cast the server turns down is gone all the same: a client that's short of what the server has only
				-- fills up sooner, one that gave itself casts back could go on asking for good
				context.Record[ROUNDS_KEY] = Module.getRounds(ability, context.Record) - 1
			end
			context.Record[CAST_COUNT_KEY] = context.Record[COUNT_KEY] or 0
			-- every ray of a cast goes where the player pointed as it began, wherever they point by the time it
			-- leaves. the click says where that is, a cast that follows by itself has to ask
			local aim = if cast == bindings.Cast then context.Aim or context.getAim() else context.getAim()
			local elapsed = 0
			for index = 1, RayFactory.getCount(shared) do
				local delay = RayFactory.getReleaseDelay(shared, index)
				if delay > elapsed then
					task.wait(delay - elapsed)
					elapsed = delay
				end
				release(context, aim, index)
			end
		end)
	end

	local holdAnimation = config.HoldAnimation
	if holdAnimation then
		builder = builder:Run(bindings.Hold, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
			return { Animation = holdAnimation :: AnimationKey }
		end)
	end

	for _, prop in shared.Props do
		builder = builder:Run(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ClientContext): ClientVFXType.Prop
				return RayFactory.getProp(shared, prop, context.Color)
			end
		)
	end

	local plumes: { ClientVFXType.Plume } = shared.Plumes or {}
	for _, plume in plumes do
		builder = builder:Run(bindings.Hold, ClientVFXDefinition.Plume, function(): ClientVFXType.Plume
			return plume
		end)
	end

	-- every beam of a ray is an effect of its own
	for index in shared.Beams do
		builder = builder:Fire(
			bindings.Fire,
			ClientVFXDefinition.Beam,
			function(context: ClientContext): ClientVFXType.Beam
				local fire = context.read(bindings.Fire) :: RayFactory.Fire
				return RayFactory.getBeams(ability, fire, fire.Distance, context.Color, context.SecondaryColor)[index]
			end
		)
	end

	local fireAnimation = config.FireAnimation
	if fireAnimation then
		builder = builder:Fire(bindings.Fire, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
			return { Animation = fireAnimation :: AnimationKey }
		end)
	end

	if shared.Flare then
		builder = builder:On(bindings.Fire, function(context: ClientContext)
			local fire = context.read(bindings.Fire) :: RayFactory.Fire
			-- which ray of its cast it is says which spot it left from
			local index = fire.Id - ((context.Record[CAST_COUNT_KEY] or 0) :: number)
			local flare = RayFactory.getFlare(shared, index)
			if flare then
				context.VFX.fire(ClientVFXDefinition.Flare, flare)
			end
		end)
	end

	-- a ray that ran into nothing leaves nothing behind
	if shared.Shaft then
		builder = builder:On(bindings.Fire, function(context: ClientContext)
			local fire = context.read(bindings.Fire) :: RayFactory.Fire
			local shaft = RayFactory.getShaft(ability, fire, fire.Distance, context.Color, context.SecondaryColor)
			if shaft then
				context.VFX.fire(ClientVFXDefinition.Shaft, shaft)
			end
		end)
	end

	-- not every ray is heard as it leaves
	local fireSound = shared.FireSound
	if fireSound then
		builder = builder:Fire(bindings.Fire, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = fireSound :: VFXAssetDefinition.SoundKey }
		end)
	end

	local held = bindings.Held
	local heldSound = shared.HeldSound
	if held and heldSound then
		builder = builder:Run(held, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
			return { Sound = heldSound :: VFXAssetDefinition.SoundKey }
		end)
	end

	local reloadKey = bindings.ReloadKey
	local reloaded = bindings.Reloaded
	if clip and reload and reloadKey and reloaded then
		builder = builder
			:On(reloadKey, function(context: ClientContext)
				if Module.getRounds(ability, context.Record) < clip.Size then
					context.raise(reload, nil)
				end
			end)
			:On(reload, function(context: ClientContext)
				context.Record[RELOAD_TIME_KEY] = os.clock()
			end)
			-- the server only turns it down with a clip that's full: this one is put right by it
			:Undo(
				reload,
				function(context: ClientContext)
					context.Record[RELOAD_TIME_KEY] = nil
					context.Record[ROUNDS_KEY] = clip.Size
				end
			)
			:On(reloaded, function(context: ClientContext)
				context.Record[RELOAD_TIME_KEY] = nil
				context.Record[ROUNDS_KEY] = clip.Size
			end)
	end

	return builder
end

return Module
