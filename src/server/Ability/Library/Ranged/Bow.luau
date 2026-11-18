--!strict
-- Services
-- Packages
-- Modules
local Bow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Bow")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GunFactory = require("@game/ServerScriptService/Server/Ability/Factory/Gun")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
-- seconds the arrow is gone for by the time the string is heard
local SOUND_DELAY = 0.2
-- studs everybody else hears the string from
local SOUND_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory
	.new(Bow)
	-- the player's own machine lets them hear it, this is for everybody else
	:On(
		Bow.Layout.Bindings.Launch,
		function(context: ServerContext)
			task.delay(SOUND_DELAY, function()
				context.VFX.fireClient(
					ClientVFXDefinition.Sound,
					{ Sound = "Bow" },
					{ Audience = "Others", Range = SOUND_RANGE }
				)
			end)
		end
	)
	:Build()
