--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Emitter = require("@self/Emitter")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Sound
-- Constants
-- a sound that never loads never ends either
local MAX_DURATION = 20
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.event(ClientVFXDefinition.Sound, function(props: Properties, scope: ClientScope)
	local function play()
		local sound = Emitter.play(scope.Character, props.Sound, false)
		if not sound then
			return
		end
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		task.delay(MAX_DURATION, function()
			sound:Destroy()
		end)
	end
	if props.Delay and props.Delay > 0 then
		task.delay(props.Delay, play)
	else
		play()
	end
end)
