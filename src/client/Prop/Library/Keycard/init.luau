--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Keycard = require("@game/ReplicatedStorage/Shared/Prop/Library/Keycard")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
local PropPose = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Pose")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = PropType.ClientContext
type Cleanup = VFXType.Cleanup
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the player sees the card in their hand the moment they get it out
return PropBuilder.newClient(Keycard.Prop)
	:While(PropMoment.Hold, function(context: ClientContext): Cleanup
		return PropPose.hold(context, Keycard.HoldAnimation)
	end)
	:Run(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Keycard.Card
	end)
	:Build()
