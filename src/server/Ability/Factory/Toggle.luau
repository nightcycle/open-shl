--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local ToggleFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Toggle")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
-- what an ability keeps of when it was last turned off
local FINISH_TIME_KEY = "FinishTime"
-- seconds a client may be early by: the two sides never see it go off at quite the same moment
local COOLDOWN_TOLERANCE = 0.15
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the server half of a toggled ability: turning it on costs energy, turning it off is free. what's true of the
-- character while it's on is each ability's own to add
Module.new = function(ability: ToggleFactory.Ability): AbilityBuilder.ServerBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	local builder = AbilityBuilder.newServer(layout)
	-- one that has to wait before it's turned on again is turned down ahead of what it costs: a cast that's too early
	-- takes no energy
	local cooldown = ability.Config.Cooldown
	if cooldown then
		builder = builder
			:On(bindings.Finish, function(context: ServerContext)
				context.Record[FINISH_TIME_KEY] = os.clock()
			end)
			:Guard(bindings.Cast, function(context: ServerContext): boolean
				local finishTime = context.Record[FINISH_TIME_KEY] :: number?
				return finishTime == nil or os.clock() - finishTime >= cooldown - COOLDOWN_TOLERANCE
			end)
	end
	return builder:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = energyCost })
	end)
end

return Module
