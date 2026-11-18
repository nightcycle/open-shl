--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ServerScriptService/Server/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceExplosion = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/ForceExplosion")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else sees the wave from
local RIPPLE_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
return BurstFactory
	.new(ForceExplosion)
	-- the player's own machine shows them their wave right away, this is for everybody else
	:FireClient(
		ForceExplosion.Layout.Bindings.Release,
		ClientVFXDefinition.Ripple,
		function(context: ServerContext): ClientVFXType.Ripple
			return ForceExplosion.getRipple(context.Character)
		end,
		{ Audience = "Others", Range = RIPPLE_RANGE }
	)
	:Build()
