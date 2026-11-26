--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Moneybag = require("@game/ReplicatedStorage/Shared/Prop/Library/Moneybag")
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
-- the player sees + hears their own throw at once, the bills of it are theirs alone
return PropBuilder.newClient(Moneybag.Prop)
	:While(PropMoment.Hold, function(context: ClientContext): Cleanup
		return PropPose.hold(context, Moneybag.HoldAnimation)
	end)
	:Run(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Moneybag.Look
	end)
	:Fire(PropMoment.Use, ClientVFXDefinition.Sound, Moneybag.getSound)
	:Fire(PropMoment.Use, ClientVFXDefinition.Scatter, function(): ClientVFXType.Scatter
		return Moneybag.Bills
	end)
	:Build()
