--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Flight = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Flight")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- studs the avatar rises as it takes off
local HEIGHT = 10
-- studs ahead of itself the avatar is pulled to
local POWER = 35
-- Variables
-- References
-- Private Functions
-- Class
local layout = Flight.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the client half of the flight: the avatar is the player's own to move, so what holds it up + pulls it along is
-- all here, everybody else sees where it ends up
return AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a flight it's sure to end right away isn't started on
	:Guard(
		bindings.TakeOff,
		function(context: ClientContext): boolean
			local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
			if BUILD_CONFIG.ENERGY_ENABLED and energy < energyCost then
				context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
				return false
			end
			return true
		end
	)
	:Run(bindings.Aloft, ClientVFXDefinition.Hover, function(): ClientVFXType.Hover
		return { Height = HEIGHT }
	end)
	:Run(bindings.Aloft, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
		return { Sound = Flight.Config.Sound }
	end)
	:Run(bindings.Idle, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "FlightIdle" }
	end)
	:Run(bindings.Thrust, ClientVFXDefinition.Thrust, function(): ClientVFXType.Thrust
		return { Power = POWER }
	end)
	:Run(bindings.Thrust, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "FlightMovement" }
	end)
	:Build()
