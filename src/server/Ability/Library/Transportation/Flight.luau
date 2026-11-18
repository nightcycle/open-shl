--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local DrainEnergy = require("@game/ServerScriptService/Server/VFX/Library/DrainEnergy")
local Flight = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Flight")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
type SoundKey = VFXAssetDefinition.SoundKey
-- Constants
-- seconds between two takes of energy off whoever is up
local DRAIN_INTERVAL = 0.9
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
-- the server half of the flight: staying up costs energy + everybody else gets to hear it. the avatar is moved by
-- the client of its player, where it is + how it holds itself gets to the others by itself
local builder = AbilityBuilder
	.newServer(layout)
	-- the first take is as the avatar leaves the ground, so there's nothing to turn a take off down with: one without
	-- the energy for it is over the moment it began + a client that's up already hears of it like of any other end
	:Run(
		bindings.Aloft,
		DrainEnergy,
		function(context: ServerContext): DrainEnergy.Properties
			return {
				Amount = energyCost,
				Interval = DRAIN_INTERVAL,
				OnEmpty = function()
					context.raise(bindings.Exhaust, nil)
				end,
			}
		end
	)
-- the player's own machine has the wind around them + what they leave behind on right away, this is for everybody
-- else. not every game has either
local sound = config.Sound
if sound then
	builder = builder:RunClient(bindings.Aloft, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
		return { Sound = sound :: SoundKey }
	end, { Audience = "Others" })
end
local wake = config.Wake
if wake then
	builder = builder:RunClient(
		bindings.Aloft,
		ClientVFXDefinition.Wake,
		function(context: ServerContext): ClientVFXType.Wake
			return {
				Color = context.Color or wake.Color,
				SecondaryColor = context.SecondaryColor or wake.SecondaryColor,
				Lifetime = wake.Lifetime,
				Depth = wake.Depth,
			}
		end,
		{ Audience = "Others" }
	)
end

return builder:Build()
