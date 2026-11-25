--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AcrobaticsDefinition = require("@game/ReplicatedStorage/Shared/Definition/Acrobatics")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local MOVE_NAMES: { string } = {}
for _, move in AcrobaticsDefinition.MOVES do
	table.insert(MOVE_NAMES, move.Name)
end
table.freeze(MOVE_NAMES)
-- Variables
-- References
-- Private Functions
-- Class
-- the user goes through the move that's picked once + is put back where it stood: nothing is simulated in here, so
-- it's carried along the plan of the move + never lands. the button plays it again
return VFXStory.newStateStory({
	Move = UILabs.Choose(MOVE_NAMES),
}, function(stage: VFXStory.Stage, controls)
	for _, move in AcrobaticsDefinition.MOVES do
		if move.Name == controls.Move then
			return stage.ClientScope.start(ClientVFXDefinition.Tumble, {
				Up = move.Up,
				Forward = move.Forward,
				Phases = move.Phases,
				IsTurned = move.IsTurned,
			}).Stop
		end
	end
	return function() end
end)
