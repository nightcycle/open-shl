--!strict
-- Services
-- Packages
-- Modules
local Bow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Bow")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local GunFactory = require("@game/ServerScriptService/Server/Ability/Factory/Gun")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- seconds the arrow is gone for by the time the string is heard, the one of shl1 is heard as it lets go
local SOUND_DELAY = GameDefinition.tune(0.2, { shl1 = 0 })
-- studs everybody else hears the string from
local SOUND_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory
	.new(Bow)
	-- the player's own machine lets them hear it, this is for everybody else
	:FireClient(
		Bow.Layout.Bindings.Launch,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = "Bow", Delay = SOUND_DELAY }
		end,
		{ Audience = "Others", Range = SOUND_RANGE }
	)
	:Build()
