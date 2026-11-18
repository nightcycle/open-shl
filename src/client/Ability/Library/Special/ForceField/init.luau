--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceField = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/ForceField")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local layout = ForceField.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
return AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a wall it's sure to turn down isn't started on
	:Guard(
		bindings.Cast,
		function(context: ClientContext): boolean
			local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
			if ModeDefinition.getIfEnergyEnabled() and energy < energyCost then
				context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
				return false
			end
			return true
		end
	)
	-- the wall itself is the server's to make, what it sounds like doesn't have to wait for it
	:Fire(
		bindings.Rise,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = ForceField.Sound }
		end
	)
	:Build()
