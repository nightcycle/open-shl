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
-- the ones made to be held come first
local ANIMATIONS: { VFXAssetDefinition.AnimationKey } = {
	"FlightIdle",
	"FlightMovement",
	"GunHolding",
	"BowHolding",
	"WallClimbing",
	"Sheathing",
	"ClawSheathing",
	"KnifeSlash",
	"KnifeJab",
	"RightSlash",
	"LeftSlash",
	"PowerPunch",
	"Strike",
	"RightFootKick",
	"ForcePush",
	"ForceExplosion",
	"IceSpin",
	"PowerShot",
	"HeadShot",
	"GunShooting",
	"BowShooting",
}
-- Variables
-- References
-- Private Functions
-- Class
return VFXStory.newStateStory({
	Animation = UILabs.Choose(ANIMATIONS),
	FadeTime = UILabs.Slider(0.1, 0, 2, 0.05),
	Speed = UILabs.Slider(1, 0.1, 4, 0.1),
}, function(stage: VFXStory.Stage, controls)
	return stage.ClientScope.start(ClientVFXDefinition.Animation, {
		Animation = controls.Animation,
		FadeTime = controls.FadeTime,
		Speed = controls.Speed,
	}).Stop
end)
