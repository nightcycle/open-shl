--!strict
-- Services
-- Packages
-- Modules
local Burn = require("@game/ServerScriptService/Server/VFX/Library/Burn")
local FireRay = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FireRay")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
local TICK_COUNT = 10
-- seconds between two ticks
local TICK_INTERVAL = 0.5
-- seconds whoever it caught is seen on fire
local FLAME_DURATION = 5
-- Variables
-- References
-- Private Functions
-- Class
local powerRes = PowerDefinition.get(FireRay.Layout.Id)
assert(powerRes.IsOk, `no power is registered as "{FireRay.Layout.Id}"`)
-- what it's listed with is dealt out over the ticks, each rounded up: the burn comes to a little more
local tickAmount = math.ceil(powerRes.Value.Damage / TICK_COUNT)
-- the ray takes nothing off, the burn it starts does: a tick hurts whoever the game lets its caster hurt + sends
-- them nowhere. a wall isn't set alight + holds nobody up
return RayFactory.new(FireRay, function(context: ServerContext, target: Model): boolean?
	return context.VFX.fire(Burn, {
		Target = target,
		Amount = tickAmount,
		Count = TICK_COUNT,
		Interval = TICK_INTERVAL,
		FlameDuration = FLAME_DURATION,
	})
end):Build()
