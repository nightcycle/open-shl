--!strict
-- Services
-- Packages
-- Modules
local Bow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Bow")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local GunFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Gun")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- seconds the arrow is gone for by the time the string is heard, the one of shl1 is heard as it lets go
local SOUND_DELAY = GameDefinition.tune(0.2, { shl1 = 0 })
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
