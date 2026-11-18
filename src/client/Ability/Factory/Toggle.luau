--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ToggleFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Toggle")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the client half of a toggled ability: all there is to it for every one of them is not to start on what the server
-- is sure to turn down, what it looks like while it's on is each ability's own to add
Module.new = function(ability: ToggleFactory.Ability): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	return AbilityBuilder.newClient(layout):Guard(bindings.Cast, function(context: ClientContext): boolean
		local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
		if BUILD_CONFIG.ENERGY_ENABLED and energy < energyCost then
			context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
			return false
		end
		return true
	end)
end

return Module
