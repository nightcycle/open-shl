--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Smoke
-- Constants
-- seconds what's left of it gets to clear for once it's stopped
local FADE_DURATION = 2.25
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Smoke, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return function() end
	end
	local smoke = Instance.new("Smoke")
	smoke.Size = props.Size
	smoke.RiseVelocity = props.RiseVelocity
	smoke.Opacity = props.Opacity
	smoke.Color = props.Color
	smoke.Parent = limb
	return function()
		smoke.Enabled = false
		task.delay(FADE_DURATION, function()
			smoke:Destroy()
		end)
	end
end)
