--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Flight = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Flight")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
type SoundKey = VFXAssetDefinition.SoundKey
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local layout = Flight.Layout
local bindings = layout.Bindings
local config = Flight.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the client half of the flight: the avatar is the player's own to move, so what holds it up + pulls it along is
-- all here, everybody else sees where it ends up
local builder = AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a flight it's sure to end right away isn't started on
	:Guard(
		bindings.TakeOff,
		function(context: ClientContext): boolean
			local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
			if ModeDefinition.getIfEnergyEnabled() and energy < energyCost then
				context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
				return false
			end
			return true
		end
	)
	:Run(bindings.Aloft, ClientVFXDefinition.Hover, function(): ClientVFXType.Hover
		return { Height = config.Height }
	end)
	:Run(bindings.Idle, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "FlightIdle" }
	end)
	:Run(bindings.Thrust, ClientVFXDefinition.Thrust, function(): ClientVFXType.Thrust
		return { Power = config.Power }
	end)
	:Run(bindings.Thrust, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "FlightMovement" }
	end)
-- not every game has wind around whoever is up, widens their view as they're pulled along or has them leave
-- something behind
local sound = config.Sound
if sound then
	builder = builder:Run(bindings.Aloft, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
		return { Sound = sound :: SoundKey }
	end)
end
local fieldOfView = config.FieldOfView
if fieldOfView then
	-- a camera is its player's own, nobody else has theirs widened
	builder = builder:Run(bindings.Thrust, ClientVFXDefinition.FieldOfView, function(): ClientVFXType.FieldOfView
		return fieldOfView
	end)
end
local wake = config.Wake
if wake then
	builder = builder:Run(bindings.Aloft, ClientVFXDefinition.Wake, function(context: ClientContext): ClientVFXType.Wake
		return {
			Color = context.Color or wake.Color,
			SecondaryColor = context.SecondaryColor or wake.SecondaryColor,
			Lifetime = wake.Lifetime,
			Depth = wake.Depth,
		}
	end)
end

return builder:Build()
