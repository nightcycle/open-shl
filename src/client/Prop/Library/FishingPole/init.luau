--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local FishingPole = require("@game/ReplicatedStorage/Shared/Prop/Library/FishingPole")
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
-- the player sees the pole in their hand at once. a click is told to the server with where it pointed + that's all
-- this half does with it: the line is the server's to show, to whoever holds the pole as to everybody else
return PropBuilder.newClient(FishingPole.Prop)
	:While(PropMoment.Hold, function(context: ClientContext): Cleanup
		return PropPose.hold(context, FishingPole.HoldAnimation)
	end)
	:Run(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return FishingPole.Pole
	end)
	:Build()
