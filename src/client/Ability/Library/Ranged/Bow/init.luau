--!strict
-- Services
-- Packages
-- Modules
local Bow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Bow")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GunFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Gun")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientContext = AbilityType.ClientContext
-- Constants
-- seconds the arrow is gone for by the time the string is heard
local SOUND_DELAY = 0.2
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new(Bow, {
	CastAnimation = "BowShooting",
	HoldAnimation = "BowHolding",
})
	:On(Bow.Layout.Bindings.Launch, function(context: ClientContext)
		task.delay(SOUND_DELAY, function()
			context.VFX.fire(ClientVFXDefinition.Sound, { Sound = "Bow" })
		end)
	end)
	:Build()
