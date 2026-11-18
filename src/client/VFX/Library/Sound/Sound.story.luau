--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local SOUNDS: { VFXAssetDefinition.SoundKey } = { "Slash", "Boom", "Bow", "ForceWhoosh", "GunShot", "Impact", "PewPew" }
-- Variables
-- References
-- Private Functions
-- Class
return VFXStory.newEventStory({
	Sound = UILabs.Choose(SOUNDS),
}, function(stage: VFXStory.Stage, controls)
	stage.ClientScope.fire(ClientVFXDefinition.Sound, { Sound = controls.Sound })
end)
