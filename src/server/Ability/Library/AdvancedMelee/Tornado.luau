--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ServerScriptService/Server/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Hoist = require("@game/ServerScriptService/Server/VFX/Library/Hoist")
local Tornado = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/Tornado")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs whoever is caught is picked up by + seconds they're held up there for
local LIFT_HEIGHT = 5
local LIFT_DURATION = 3
-- Variables
-- References
-- Private Functions
-- Class
return BurstFactory
	.new(Tornado, function(context: ServerContext, target: Model)
		context.VFX.fire(Hoist, { Target = target, Height = LIFT_HEIGHT, Duration = LIFT_DURATION })
	end)
	-- the player's own machine has the wind around them on right away, this is for everybody else
	:RunClient(
		Tornado.Layout.Bindings.Surge,
		ClientVFXDefinition.Plume,
		function(): ClientVFXType.Plume
			return Tornado.Funnel
		end,
		{ Audience = "Others" }
	)
	:Build()
