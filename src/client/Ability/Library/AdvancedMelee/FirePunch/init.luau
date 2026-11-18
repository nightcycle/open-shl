--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local FirePunch = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/FirePunch")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local bindings = FirePunch.Layout.Bindings
return BurstFactory.new(FirePunch, {
	CastAnimation = "ForcePush",
})
	:Run(bindings.Hold, ClientVFXDefinition.Flame, function(context: ClientContext): ClientVFXType.Flame
		return FirePunch.getFlame(context.Color)
	end)
	:On(bindings.Release, function(context: ClientContext)
		local blaze = FirePunch.getBlaze(context.Character, context.Color)
		if blaze then
			context.VFX.fire(ClientVFXDefinition.Bolt, blaze)
		end
	end)
	:Build()
