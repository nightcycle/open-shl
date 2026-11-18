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
-- the ones that bear being looped come first
local SOUNDS: { VFXAssetDefinition.SoundKey } = {
	"Wind",
	"WindGust",
	"Platforming",
	"ForceWhoosh",
	"Shock",
	"Transwarp",
	"PortalShot",
	"Boom",
	"Bow",
	"GunShot",
	"Impact",
	"PewPew",
	"Sheath",
	"Slash",
	"Unsheath",
}
-- Variables
-- References
-- Private Functions
-- Class
return VFXStory.newStateStory({
	Sound = UILabs.Choose(SOUNDS),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.SoundLoop, { Sound = controls.Sound }).Stop
end)
