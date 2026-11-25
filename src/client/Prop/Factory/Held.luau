--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local HeldFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Held")
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

-- the client half of a prop that's only held: the player sees it in their hand the moment they get it out
Module.new = function(held: HeldFactory.Held): PropBuilder.ClientBuilder
	return PropBuilder.newClient(held.Prop)
		:While(PropMoment.Hold, function(context: ClientContext): Cleanup
			return PropPose.hold(context, held.HoldAnimation)
		end)
		:Run(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
			return held.Look
		end)
end

return Module
