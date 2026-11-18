--!strict
-- Services
local StarterPlayer = game:GetService("StarterPlayer")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.WalkSpeed
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.WalkSpeed, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return function() end
	end
	humanoid.WalkSpeed = props.WalkSpeed
	return function()
		-- back to the pace every avatar starts out with rather than the one this one had: whatever held it still as
		-- the effect began would be made to last
		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
	end
end)
