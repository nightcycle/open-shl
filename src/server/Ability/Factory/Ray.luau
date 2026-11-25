--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local BodyUtil = require("@game/ReplicatedStorage/Shared/Util/Body")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Heal = require("@game/ServerScriptService/Server/VFX/Library/Heal")
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerContext = AbilityType.ServerContext
-- what the server makes of a ray its client let go
type Answer = {
	Distance: number, -- studs it got
	Target: Model?, -- who it landed on
	IsCut: boolean, -- it ended sooner than its client had it
}
-- Constants
-- studs from the middle of the avatar a ray may leave from: it starts out at the end of a limb + the two sides never
-- see an avatar in quite the same spot
local ORIGIN_RANGE = 10
-- studs a target may be off the path of a ray: it's hit wherever it sticks out + held to its middle, which the two
-- sides never see in quite the same spot. the world has to be in the way that far short of where a ray ended as well
-- before the server has it end there
local PATH_TOLERANCE = 6
-- seconds ahead of its turn a ray of a cast may leave: the machine of the server is that far ahead of the clock as
-- well, so a client that's on time isn't turned down over a hiccup of its connection
local RELEASE_TOLERANCE = 0.15
-- studs everybody else hears a ray leave from
local SOUND_RANGE = 150
-- when the cast began that's letting its rays go
local CAST_TIME_KEY = "CastTime"
-- how many rays that cast let go so far
local COUNT_KEY = "RayCount"
-- when the next cast of an ability that's held is due
local NEXT_CAST_TIME_KEY = "NextCastTime"
-- casts left in the clip, full without. the count that counts
local ROUNDS_KEY = "Rounds"
-- Variables
-- References
-- Private Functions
-- how far a spot is off a straight stretch
local function getStretchDistance(origin: Vector3, direction: Vector3, length: number, position: Vector3): number
	local along = math.clamp((position - origin):Dot(direction), 0, length)
	return (origin + direction * along - position).Magnitude
end
-- Class
local Module = {}

-- the server half of a ray ability: a cast costs energy + lets go of as many rays as it has, each from where the
-- server has the avatar. who a ray lands on is the server's to say: the target its client names has to be on its way
-- with nothing of the world before them. everybody else is shown the ray as far as the server has it go, its own
-- player only if that's not where they had it end. what a ray that landed sets off besides is the ability's to say:
-- true from it has whatever it set off hold the caster up, for an ability that can be
Module.new = function(
	ability: RayFactory.Ability,
	onLanded: ((context: ServerContext, target: Model, fire: RayFactory.Fire) -> boolean?)?
): AbilityBuilder.ServerBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local power = powerRes.Value
	local rayCount = RayFactory.getCount(shared)
	local clip = shared.Clip
	local heal = shared.Heal
	local stall = bindings.Stall
	-- a spot off the middle of the limb is that much further out to begin with
	local originRange = ORIGIN_RANGE
	for index = 1, if shared.Offsets then #shared.Offsets else 1 do
		local offset = RayFactory.getOffset(shared, index)
		originRange = math.max(originRange, ORIGIN_RANGE + (if offset then offset.Magnitude else 0))
	end

	local function getRounds(context: ServerContext): number
		return if clip then (context.Record[ROUNDS_KEY] or clip.Size) :: number else math.huge
	end

	local function getAnswer(context: ServerContext, fire: RayFactory.Fire): Answer
		local direction = fire.Direction.Unit
		local distance = fire.Distance
		-- the world as the server has it: a client may not have been sent all of what's between it + what it shot at
		local sightRange = distance - PATH_TOLERANCE
		if sightRange > 0 then
			local sight = context.VFX.fire(Hitscan, {
				Origin = fire.Origin,
				Direction = direction,
				Range = sightRange,
				IsPassingCharacters = true,
			})
			if sight and sight.Instance then
				return { Distance = sight.Distance, IsCut = true }
			end
		end
		local target = fire.Target
		if not target or target == context.Character or not target:FindFirstChildWhichIsA("Humanoid") then
			return { Distance = distance, IsCut = false }
		end
		local length = math.min(distance + PATH_TOLERANCE, shared.Range)
		-- a body nobody plays is held to the closest of it to where the ray ended, not to a middle that's far off
		local aimPosition = BodyUtil.getAimPosition(target, fire.Origin + direction * distance)
		local offPath = getStretchDistance(fire.Origin, direction, length, aimPosition)
		return {
			Distance = distance,
			Target = if offPath <= PATH_TOLERANCE then target else nil,
			IsCut = false,
		}
	end

	local builder = AbilityBuilder.newServer(layout)
	for _, cast in RayFactory.getCasts(ability) do
		if shared.IsHeld then
			-- the machine doesn't hold one that's held to its pace: the server is ahead of a wait this short + the
			-- next cast is its client's to call. a cast may be as early as a ray may, what it's early by isn't kept
			builder = builder:Guard(cast, function(context: ServerContext): boolean
				return os.clock() + RELEASE_TOLERANCE >= ((context.Record[NEXT_CAST_TIME_KEY] or 0) :: number)
			end)
		end
		if clip then
			builder = builder:Guard(cast, function(context: ServerContext): boolean
				return getRounds(context) >= 1
			end)
		end
		builder = builder
			:Guard(cast, function(context: ServerContext): boolean
				return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
			end)
			:On(cast, function(context: ServerContext)
				local now = os.clock()
				context.Record[CAST_TIME_KEY] = now
				context.Record[COUNT_KEY] = 0
				if shared.IsHeld then
					local nextCastTime = (context.Record[NEXT_CAST_TIME_KEY] or 0) :: number
					context.Record[NEXT_CAST_TIME_KEY] = math.max(nextCastTime, now) + shared.Duration
				end
				if clip then
					context.Record[ROUNDS_KEY] = getRounds(context) - 1
				end
			end)
	end
	builder = builder
		-- a cast lets go of the rays it has + no more, none ahead of its turn, from where the server has its avatar
		:Guard(
			bindings.Fire,
			function(context: ServerContext): boolean
				local fire = context.read(bindings.Fire)
				local castTime = context.Record[CAST_TIME_KEY] :: number?
				local count = (context.Record[COUNT_KEY] or 0) :: number
				if not fire or not castTime or count >= rayCount then
					return false
				end
				local releaseDelay = RayFactory.getReleaseDelay(shared, count + 1)
				return os.clock() - castTime + RELEASE_TOLERANCE >= releaseDelay
					and context.VFX.fire(Reach, { Position = fire.Origin, Range = originRange })
			end
		)
		:On(bindings.Fire, function(context: ServerContext)
			local fire = context.read(bindings.Fire)
			if not fire then
				return
			end
			local index = ((context.Record[COUNT_KEY] or 0) :: number) + 1
			context.Record[COUNT_KEY] = index
			local answer = getAnswer(context, fire)
			-- the player's own machine showed them their ray right away, this is for everybody else. it's theirs as
			-- well once it ended sooner than they had it: under the key of the beam they drew it takes its place
			local audience: VFXType.Audience = if answer.IsCut then "All" else "Others"
			for _, beam in RayFactory.getBeams(ability, fire, answer.Distance, context.Color, context.SecondaryColor) do
				context.VFX.fireClient(ClientVFXDefinition.Beam, beam, {
					Audience = audience,
					Range = shared.Range,
				})
			end
			local shaft = RayFactory.getShaft(ability, fire, answer.Distance, context.Color, context.SecondaryColor)
			if shaft then
				context.VFX.fireClient(ClientVFXDefinition.Shaft, shaft, { Audience = audience, Range = shared.Range })
			end
			local flare = RayFactory.getFlare(shared, index)
			if flare then
				context.VFX.fireClient(ClientVFXDefinition.Flare, flare, { Audience = "Others", Range = SOUND_RANGE })
			end
			local target = answer.Target
			if not target then
				return
			end
			local isLanded: boolean
			if heal then
				-- the same question a hit asks: who can't be hurt by them can't be helped by them either
				isLanded = CombatDefinition.getIfHostile(context.Character, target)
					and context.VFX.fire(Heal, { Target = target, Amount = heal })
			elseif shared.IsHarmless then
				isLanded = true
			else
				isLanded = context.VFX.fire(Attack, { Target = target, Amount = power.Damage, Origin = fire.Origin })
			end
			if isLanded and onLanded and onLanded(context, target, fire) and stall then
				context.raise(stall, nil)
			end
		end)

	-- the player's own machine shows them what they hold right away, this is for everybody else
	for _, prop in shared.Props do
		builder = builder:RunClient(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ServerContext): ClientVFXType.Prop
				return RayFactory.getProp(shared, prop, context.Color)
			end,
			{ Audience = "Others" }
		)
	end

	local plumes: { ClientVFXType.Plume } = shared.Plumes or {}
	for _, plume in plumes do
		builder = builder:RunClient(bindings.Hold, ClientVFXDefinition.Plume, function(): ClientVFXType.Plume
			return plume
		end, { Audience = "Others" })
	end

	-- not every ray is heard as it leaves
	local fireSound = shared.FireSound
	if fireSound then
		builder = builder:FireClient(bindings.Fire, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = fireSound :: VFXAssetDefinition.SoundKey }
		end, { Audience = "Others", Range = SOUND_RANGE })
	end

	local held = bindings.Held
	local heldSound = shared.HeldSound
	if held and heldSound then
		builder = builder:RunClient(held, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
			return { Sound = heldSound :: VFXAssetDefinition.SoundKey }
		end, { Audience = "Others", Range = SOUND_RANGE })
	end

	-- the clip is the server's: it's only filled when it's short + it's full once that took its time
	local reload = bindings.Reload
	local reloaded = bindings.Reloaded
	if clip and reload and reloaded then
		builder = builder
			:Guard(reload, function(context: ServerContext): boolean
				return getRounds(context) < clip.Size
			end)
			:On(reloaded, function(context: ServerContext)
				context.Record[ROUNDS_KEY] = clip.Size
			end)
	end

	return builder
end

return Module
