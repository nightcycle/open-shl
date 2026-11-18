--!strict
-- Services
-- Packages
-- Modules
local Bow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Bow")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GunFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Gun")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
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
	:Fire(Bow.Layout.Bindings.Launch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = "Bow", Delay = SOUND_DELAY }
	end)
	:Build()
