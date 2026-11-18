--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Emitter = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library/Sound/Emitter")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.SoundLoop
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.SoundLoop, function(props: Properties, scope: ClientScope)
	local sound = Emitter.play(scope.Character, props.Sound, true)
	return function()
		if sound then
			sound:Destroy()
		end
	end
end)
