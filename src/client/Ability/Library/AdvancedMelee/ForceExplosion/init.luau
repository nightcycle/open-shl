--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceExplosion = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/ForceExplosion")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local bindings = ForceExplosion.Layout.Bindings
return BurstFactory.new(ForceExplosion, {
	CastAnimation = "ForceExplosion",
})
	:Fire(bindings.Release, ClientVFXDefinition.Ripple, function(context: ClientContext): ClientVFXType.Ripple
		return ForceExplosion.getRipple(context.Character)
	end)
	:On(bindings.Subside, BurstFactory.strike(ForceExplosion))
	:Build()
