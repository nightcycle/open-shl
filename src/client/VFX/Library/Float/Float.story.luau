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
-- Variables
-- References
-- Private Functions
-- Class
-- nothing falls in a place that isn't running, what the dummy is pushed up with is printed as the effect starts
return VFXStory.newStateStory({
	Share = UILabs.Slider(0.8, 0, 1, 0.05),
}, function(stage: VFXStory.Stage, controls)
	local handle = stage.ClientScope.start(ClientVFXDefinition.Float, { Share = controls.Share })
	local rootPart = stage.User.PrimaryPart
	local vectorForce = rootPart and rootPart:FindFirstChildWhichIsA("VectorForce")
	print(`pushed up with {vectorForce and vectorForce.Force.Y}, it weighs {rootPart and rootPart.AssemblyMass}`)
	return handle.Stop
end)
