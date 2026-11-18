--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local BurstFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- what the server knows of a cast that can still get to somebody
type Cast = {
	Time: number,
	Targets: { [Model]: true }, -- who it got to so far
}
-- Constants
-- studs everybody else hears a move from
local SOUND_RANGE = 150
-- studs a target may be further off than the reach: the two sides never see an avatar in quite the same spot
local REACH_TOLERANCE = 4
-- seconds word of a hit may be early by: it's held against when the server heard of the click, which may have been
-- longer on its way than the word that follows it
local EARLY_TOLERANCE = 0.25
-- seconds past the last moment a cast can get to somebody it's kept for: word of it takes a while to get here
local WORD_DELAY = 0.5
-- seconds two hits may be closer together than their interval, for the same reason
local INTERVAL_TOLERANCE = 0.15
-- the casts of the character that can still get to somebody
local CASTS_KEY = "Casts"
-- when a hit of the character last landed
local LAST_HIT_KEY = "LastHitTime"
-- Variables
-- References
-- Private Functions
-- whatever can't get to anybody any more is dropped on the way
local function getCasts(context: ServerContext, config: BurstFactory.Config, now: number): { Cast }
	local casts: { Cast } = {}
	for _, cast in (context.Record[CASTS_KEY] or {}) :: { Cast } do
		if now - cast.Time <= config.HitDelay + config.HitDuration + WORD_DELAY then
			table.insert(casts, cast)
		end
	end
	context.Record[CASTS_KEY] = casts
	return casts
end

-- the cast a hit on the target can be of: one that's far enough along + hasn't got to them yet, unless it's one
-- that gets to the same character time + again
local function getOpenCast(context: ServerContext, config: BurstFactory.Config, target: Model, now: number): Cast?
	for _, cast in getCasts(context, config, now) do
		local isDue = now - cast.Time >= config.HitDelay - EARLY_TOLERANCE
		if isDue and (config.HitInterval ~= nil or not cast.Targets[target]) then
			return cast
		end
	end
	return nil
end
-- Class
local Module = {}

-- the server half of a burst ability: a cast costs energy, everybody else gets to hear it + a hit the client claims
-- only lands if a cast of theirs can have got to the target by then + the server finds it within reach. whatever
-- else becomes of somebody a hit landed on is up to the ability
Module.new = function(
	ability: BurstFactory.Ability,
	onLanded: ((context: ServerContext, target: Model) -> ())?
): AbilityBuilder.ServerBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local power = powerRes.Value
	local builder = AbilityBuilder.newServer(layout)
		:Guard(bindings.Cast, function(context: ServerContext): boolean
			return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
		end)
		:On(bindings.Cast, function(context: ServerContext)
			local now = os.clock()
			table.insert(getCasts(context, shared, now), { Time = now, Targets = {} })
		end)
		:Guard(bindings.Hit, function(context: ServerContext): boolean
			local hit = context.read(bindings.Hit)
			if not hit then
				return false
			end
			local target = hit.Target
			if target == context.Character or not target:FindFirstChildWhichIsA("Humanoid") then
				return false
			end
			local now = os.clock()
			local cast = getOpenCast(context, shared, target, now)
			if not cast then
				return false
			end
			local lastHitTime = (context.Record[LAST_HIT_KEY] or -math.huge) :: number
			if shared.HitInterval and now - lastHitTime < shared.HitInterval - INTERVAL_TOLERANCE then
				return false
			end
			local isInReach = context.VFX.fire(Reach, {
				Position = target:GetPivot().Position,
				Range = shared.Reach + REACH_TOLERANCE,
			})
			if not isInReach then
				return false
			end
			cast.Targets[target] = true
			context.Record[LAST_HIT_KEY] = now
			return true
		end)
		:On(bindings.Hit, function(context: ServerContext)
			local hit = context.read(bindings.Hit)
			if not hit then
				return
			end
			-- nobody is moved about by a hit the mode didn't let land
			local hasLanded = context.VFX.fire(Attack, { Target = hit.Target, Amount = power.Damage })
			if hasLanded and onLanded then
				onLanded(context, hit.Target)
			end
		end)

	-- the player's own machine lets them hear their move right away, this is for everybody else
	for binding, sound in BurstFactory.getSounds(ability) do
		builder = builder:FireClient(binding, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = sound :: VFXAssetDefinition.SoundKey }
		end, { Audience = "Others", Range = SOUND_RANGE })
	end

	return builder
end

return Module
