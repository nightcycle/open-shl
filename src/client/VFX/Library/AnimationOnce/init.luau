--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Track = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library/Animation/Track")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.AnimationOnce
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.event(ClientVFXDefinition.AnimationOnce, function(props: Properties, scope: ClientScope)
	local track, stop = Track.play(scope.Character, props, false)
	if not track then
		return
	end
	-- the length of a track isn't known until it has loaded, the one it was authored with is
	local length = VFXAssetDefinition.getAnimation(props.Animation).Length / (props.Speed or 1)
	task.delay(length, stop)
end)
