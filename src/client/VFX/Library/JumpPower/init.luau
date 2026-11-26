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
type Properties = ClientVFXType.JumpPower
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.JumpPower, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return function() end
	end
	-- a humanoid goes by how high it jumps or by what it jumps with, the effect has it go by the second
	local wasUsingJumpPower = humanoid.UseJumpPower
	humanoid.UseJumpPower = true
	humanoid.JumpPower = props.JumpPower
	return function()
		-- back to what every avatar starts out with rather than what this one had: whatever else changed it as the
		-- effect began would be made to last
		humanoid.JumpPower = StarterPlayer.CharacterJumpPower
		humanoid.UseJumpPower = wasUsingJumpPower
	end
end)
