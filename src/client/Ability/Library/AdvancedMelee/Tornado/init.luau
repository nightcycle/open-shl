--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Tornado = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/Tornado")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local bindings = Tornado.Layout.Bindings
return BurstFactory.new(Tornado, {
	CastAnimation = "IceSpin",
})
	:On(bindings.Cast, BurstFactory.strike(Tornado))
	:Run(bindings.Surge, ClientVFXDefinition.Plume, function(): ClientVFXType.Plume
		return Tornado.Funnel
	end)
	:Build()
