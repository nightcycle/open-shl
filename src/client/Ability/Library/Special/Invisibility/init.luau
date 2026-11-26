--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Invisibility = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/Invisibility")
local ToggleFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Toggle")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type SoundKey = VFXAssetDefinition.SoundKey
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local bindings = Invisibility.Layout.Bindings
-- the player is gone from their own screen as well, the moment they click
local builder = ToggleFactory.new(Invisibility)
	:Run(bindings.Sustain, ClientVFXDefinition.Cloak, function(): ClientVFXType.Cloak
		return Invisibility.Cloak
	end)
-- not every game has the avatar heard going + coming back
local castSound = Invisibility.CastSound
if castSound then
	builder = builder:Fire(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = castSound :: SoundKey }
	end)
end
local finishSound = Invisibility.FinishSound
if finishSound then
	builder = builder:Fire(bindings.Finish, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = finishSound :: SoundKey }
	end)
end

return builder:Build()
