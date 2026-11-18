--!strict
-- Services
-- Packages
-- Modules
local ToggleFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Toggle")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out takes the avatar out of sight for as long as it's on
local ability = ToggleFactory.new("special_invisibility", {
	Duration = 20,
})

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	-- what every machine makes of the avatar + what it's heard going + coming back with
	Cloak = table.freeze({ Transparency = 1 }) :: ClientVFXType.Cloak,
	CastSound = "Morph" :: VFXAssetDefinition.SoundKey,
	FinishSound = "MorphReset" :: VFXAssetDefinition.SoundKey,
})
