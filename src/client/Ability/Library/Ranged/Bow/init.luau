--!strict
-- Services
-- Packages
-- Modules
local Bow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Bow")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local GunFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Gun")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type DecalKey = VFXAssetDefinition.DecalKey
-- Constants
-- seconds the arrow is gone for by the time the string is heard, the one of shl1 is heard as it lets go
local SOUND_DELAY = GameDefinition.tune(0.2, { shl1 = 0 })
-- what the mouse points with for as long as the bow is out, the one of shl1 has a pointer of its own
local CURSOR = GameDefinition.tune(nil :: DecalKey?, { shl1 = "CursorBow" :: DecalKey? })
-- Variables
-- References
-- Private Functions
-- Class
local builder = GunFactory.new(Bow, {
	CastAnimation = "BowShooting",
	HoldAnimation = "BowHolding",
}):Fire(Bow.Layout.Bindings.Launch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
	return { Sound = "Bow", Delay = SOUND_DELAY }
end)
if CURSOR then
	builder = builder:Run(Bow.Layout.Bindings.Hold, ClientVFXDefinition.Cursor, function(): ClientVFXType.Cursor
		return { Image = CURSOR :: DecalKey }
	end)
end

return builder:Build()
