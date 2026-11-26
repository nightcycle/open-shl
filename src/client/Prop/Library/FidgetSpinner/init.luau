--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local FidgetSpinner = require("@game/ReplicatedStorage/Shared/Prop/Library/FidgetSpinner")
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
local function getLook(context: ClientContext): ClientVFXType.Prop
	return FidgetSpinner.getLook(context.Memory)
end

-- the flick comes first: what shows the use after it is handed the speed it turns at from here on
local function flick(context: ClientContext): Cleanup
	FidgetSpinner.flick(context.Memory, Workspace:GetServerTimeNow())
	return function() end
end
-- Class
-- the player sees their own flick at once: this half does the sum the server does, off the same clock
return PropBuilder.newClient(FidgetSpinner.Prop)
	:While(PropMoment.Hold, function(context: ClientContext): Cleanup
		return PropPose.hold(context, FidgetSpinner.HoldAnimation)
	end)
	:While(PropMoment.Using, flick)
	:Run(PropMoment.Rest, ClientVFXDefinition.Prop, getLook)
	:Run(PropMoment.Using, ClientVFXDefinition.Prop, getLook)
	:Build()
