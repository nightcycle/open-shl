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
-- only shl1 has pointers of its own
local IMAGES: { VFXAssetDefinition.DecalKey } = {
	"CursorBow",
	"CursorGun",
	"CursorReload",
}
-- Variables
-- References
-- Private Functions
-- Class
-- it's the pointer of the mouse over the view of the place that changes, in a place that runs
return VFXStory.newStateStory({
	Image = UILabs.Choose(IMAGES),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Cursor, { Image = controls.Image }).Stop
end)
