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
	return AbilityBuilder.newServer(layout):Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = energyCost })
	end)
end

return Module
