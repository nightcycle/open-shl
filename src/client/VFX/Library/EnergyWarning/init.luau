--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Warned = require("@self/Warned")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.event(ClientVFXDefinition.EnergyWarning, function()
	Warned:Fire()
end)
