--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local EnergyField = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/EnergyField")
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
local layout = EnergyField.Layout
local bindings = layout.Bindings
local config = EnergyField.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the client half of the field: the throw + what it sounds like. the field itself is the server's to throw, to show
-- + to make a wall of
return AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a field it's sure to turn down isn't started on
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
	:Fire(bindings.Cast, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
		return { Animation = "PowerShot" }
	end)
	:Fire(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = config.CastSound }
	end)
	:Build()
