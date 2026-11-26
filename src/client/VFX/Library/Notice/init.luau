--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Noticed = require("@self/Noticed")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Properties = ClientVFXType.Notice
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- whoever is shown it reads it: whose screen that is was the server's to pick
return ClientVFX.event(ClientVFXDefinition.Notice, function(props: Properties)
	Noticed:Fire(props)
end)
