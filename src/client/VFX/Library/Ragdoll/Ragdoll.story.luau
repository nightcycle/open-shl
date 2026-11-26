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
-- nothing falls in a place that isn't running + the root of the dummy is held where it stands: what the effect let go
-- of is printed as it starts. in a running place the limbs hang from a body that stays up
return VFXStory.newStateStory({
	Shove = UILabs.Slider(15, 0, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	local handle = stage.ClientScope.start(ClientVFXDefinition.Ragdoll, { Shove = controls.Shove })
	local names: { string } = {}
	for _, inst in stage.User:GetDescendants() do
		if inst:IsA("Motor6D") and not inst.Enabled then
			table.insert(names, inst.Name)
		end
	end
	table.sort(names)
	print(`let go of {#names} joints: {table.concat(names, ", ")}`)
	return handle.Stop
end)
