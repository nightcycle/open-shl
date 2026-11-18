--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
local Warned = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library/EnergyWarning/Warned")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the warning itself is the hud's to show, all there is to see here is whether the hud was told
return VFXStory.newEventStory({}, function(stage: VFXStory.Stage)
	local isWarned = false
	local connection = Warned:Connect(function()
		isWarned = true
	end)
	stage.ClientScope.fire(ClientVFXDefinition.EnergyWarning, {})
	connection:Disconnect()
	print(`hud warned: {isWarned}`)
end)
