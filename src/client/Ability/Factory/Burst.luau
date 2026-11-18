--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local BurstFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Front = require("@game/ReplicatedStorage/Shared/VFX/Library/Front")
local Nearby = require("@game/ReplicatedStorage/Shared/VFX/Library/Nearby")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
-- what only the player who casts needs to know
export type Config = {
	CastAnimation: VFXAssetDefinition.AnimationKey, -- from the click on
}
-- Constants
-- when the character last told of a hit, the next one is held against it
local LAST_HIT_KEY = "LastHitTime"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- tells the server of somebody the move got to. the server has the last word on it, a hit it's sure to turn down for
-- coming too soon after the last isn't told of
Module.claim = function(ability: BurstFactory.Ability): (context: ClientContext, target: Model) -> ()
	local hit = ability.Layout.Bindings.Hit
	local hitInterval = ability.Config.HitInterval
	return function(context: ClientContext, target: Model)
		if hitInterval then
			local now = os.clock()
			local lastHitTime = (context.Record[LAST_HIT_KEY] or -math.huge) :: number
			if now - lastHitTime < hitInterval then
				return
			end
			context.Record[LAST_HIT_KEY] = now
		end
		context.raise(hit, { Target = target })
	end
end

-- for a move that gets to everybody around the avatar at once: hooked onto the binding it does so at
Module.strike = function(ability: BurstFactory.Ability): (context: ClientContext) -> ()
	local claim = Module.claim(ability)
	local reach = ability.Config.Reach
	return function(context: ClientContext)
		for _, target in context.VFX.fire(Nearby, { Range = reach }) do
			claim(context, target)
		end
	end
end

-- the client half of a burst ability: the player sees + hears their own cast the moment they click, the avatar is
-- theirs to hold still + their machine is the one to notice who the move gets to
Module.new = function(ability: BurstFactory.Ability, config: Config): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	local builder = AbilityBuilder
		.newClient(layout)
		-- the server has the last word on the energy, a cast it's sure to turn down isn't started on
		:Guard(
			bindings.Cast,
			function(context: ClientContext): boolean
				local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
				if BUILD_CONFIG.ENERGY_ENABLED and energy < energyCost then
					context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
					return false
				end
				return true
			end
		)
		:Fire(bindings.Cast, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
			return { Animation = config.CastAnimation }
		end)
		:Run(bindings.Brace, ClientVFXDefinition.Root, function(): ClientVFXType.Root
			return {}
		end)

	for binding, sound in BurstFactory.getSounds(ability) do
		builder = builder:Fire(binding, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = sound :: VFXAssetDefinition.SoundKey }
		end)
	end
	-- not every move lets something leave the avatar
	if shared.Front then
		local front: BurstFactory.Front = shared.Front
		local claim = Module.claim(ability)
		builder = builder:On(bindings.Release, function(context: ClientContext)
			local cframe = BurstFactory.getFrontCFrame(context.Character, front)
			if not cframe then
				return
			end
			local handle: VFXType.Handle
			handle = context.VFX.start(Front, {
				CFrame = cframe,
				Velocity = cframe.LookVector * front.Speed,
				Size = front.Size,
				Lifetime = front.Lifetime,
				OnHit = function(target: Model)
					claim(context, target)
				end,
				OnExpired = function()
					handle.Stop()
				end,
			})
		end)
	end

	return builder
end

return Module
