--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Track = require("@self/Track")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Swap = VFXType.Swap
type Properties = ClientVFXType.Animation
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Animation, function(props: Properties, scope: ClientScope, swap: Swap?)
	-- eased in over the swap it starts with + out over the one it ends with, so two of them blend
	local startProps: Properties = if swap
		then table.freeze({
			Animation = props.Animation,
			FadeTime = swap.Duration,
			Speed = props.Speed,
		})
		else props
	local _, stop = Track.play(scope.Character, startProps, true)
	return function(stopSwap: Swap?)
		stop(if stopSwap then stopSwap.Duration else props.FadeTime)
	end
end)
