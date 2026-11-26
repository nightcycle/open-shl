--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- seconds a round of the story's clip lasts + seconds filling it takes
local ROUND_DURATION = 0.1
local RELOAD_DURATION = 5
-- Variables
-- References
-- Private Functions
-- Class
-- the bar in the bottom right corner of the view of the place: it runs dry a round at a time, fills up + starts over
return VFXStory.newStateStory({
	Caption = UILabs.String("Machine Gun"),
	Max = UILabs.Slider(45, 1, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	local max: number = controls.Max
	local startTime = os.clock()
	return stage.ClientScope.start(ClientVFXDefinition.Gauge, {
		Caption = controls.Caption,
		Max = max,
		Read = function(): (number, string?)
			local elapsed = (os.clock() - startTime) % (max * ROUND_DURATION + RELOAD_DURATION)
			local reloaded = elapsed - max * ROUND_DURATION
			if reloaded >= 0 then
				return max * reloaded / RELOAD_DURATION, "Reloading"
			end
			return max - math.floor(elapsed / ROUND_DURATION), nil
		end,
	}).Stop
end)
