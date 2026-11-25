--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ConsumableFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Consumable")
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
local Module = {}

-- the client half of something to eat or drink: the player sees + hears their own right away, out in front, up at the
-- mouth for a use, back. what a use gives is the server's
Module.new = function(consumable: ConsumableFactory.Consumable): PropBuilder.ClientBuilder
	local builder = PropBuilder.newClient(consumable.Prop)
		:While(PropMoment.Hold, function(context: ClientContext): Cleanup
			return PropPose.hold(context, consumable.HoldAnimation)
		end)
		:Run(PropMoment.Rest, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
			return consumable.Rest
		end)
		:Run(PropMoment.Using, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
			return consumable.Use
		end)
		:Fire(PropMoment.Use, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return consumable.UseSound
		end)
	local drawSound = consumable.DrawSound
	if drawSound then
		builder = builder:Fire(PropMoment.Draw, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return drawSound
		end)
	end
	return builder
end

return Module
