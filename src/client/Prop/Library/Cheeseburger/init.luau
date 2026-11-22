--!strict
-- Services
-- Packages
-- Modules
local Cheeseburger = require("@game/ReplicatedStorage/Shared/Prop/Library/Cheeseburger")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
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
-- the player sees + hears their own burger right away: out in front, up at the mouth for a bite, back. what a bite
-- gives is the server's
return PropBuilder.newClient(Cheeseburger.Prop)
	:While(PropMoment.Hold, function(context: ClientContext): Cleanup
		return PropPose.hold(context, Cheeseburger.HoldAnimation)
	end)
	:Run(PropMoment.Rest, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Cheeseburger.Rest
	end)
	:Run(PropMoment.Using, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Cheeseburger.Bite
	end)
	:Fire(PropMoment.Draw, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Cheeseburger.DrawSound }
	end)
	:Fire(PropMoment.Use, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Cheeseburger.BiteSound }
	end)
	:Build()
