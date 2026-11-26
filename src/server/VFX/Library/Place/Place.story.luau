--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Place = require("@game/ServerScriptService/Server/VFX/Library/Place")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the target is put beside the user, as far to their right + as high up as the controls say. it keeps the way it was
-- turned + comes down upright however it was tipped over by hand. whether it went is printed
return VFXStory.newEventStory({
	Side = UILabs.Slider(6, -20, 20, 0.5),
	Height = UILabs.Slider(0, 0, 30, 0.5),
}, function(stage: VFXStory.Stage, controls)
	local pivot = stage.User:GetPivot()
	local isPlaced = stage.ServerScope.fire(Place, {
		Target = stage.Target,
		Position = pivot.Position + pivot.RightVector * controls.Side + Vector3.yAxis * controls.Height,
	})
	print(`placed: {isPlaced}`)
end)
